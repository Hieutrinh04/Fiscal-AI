import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req: Request) => {
  // Chỉ chấp nhận POST
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
    });
  }

  try {
    const body = await req.json();
    console.log("[WEBHOOK] SePay payload:", JSON.stringify(body));

    // ================= PARSE SEPAY WEBHOOK DATA =================
    // SePay gửi: { id, gateway, transactionDate, accountNumber,
    //              transferType (in/out), transferAmount, accumulated,
    //              code, content, referenceCode, description }
    const {
      id: sepayId,
      gateway,
      transactionDate,
      accountNumber,
      transferType,
      transferAmount,
      accumulated,
      content,
      referenceCode,
      description,
    } = body;

    if (!accountNumber || !transferAmount) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400 }
      );
    }

    // ================= INIT SUPABASE CLIENT =================
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ================= FIND LINKED BANK ACCOUNT =================
    const { data: bankAccounts, error: bankError } = await supabase
      .from("bank_accounts")
      .select("*")
      .eq("account_number", accountNumber);

    if (bankError || !bankAccounts || bankAccounts.length === 0) {
      console.log("[WEBHOOK] No linked bank account for:", accountNumber);
      return new Response(
        JSON.stringify({ success: true, message: "No linked account" }),
        { status: 200 }
      );
    }

    const bankAccount = bankAccounts[0];
    const userId = bankAccount.user_id;
    const walletId = bankAccount.wallet_id;

    console.log(
      `[WEBHOOK] Found bank account: user=${userId}, wallet=${walletId}`
    );

    // ================= CREATE TRANSACTION =================
    const transactionType = transferType === "in" ? "income" : "expense";
    const amount = Math.abs(Number(transferAmount));

    if (walletId) {
      // Tạo transaction trong bảng transactions
      // Kiểm tra giao dịch đã tồn tại chưa (tránh duplicate)
      const { data: existing } = await supabase
        .from("transactions")
        .select("id")
        .eq("user_id", userId)
        .eq("wallet_id", walletId)
        .eq("note", `[SePay] ${content || referenceCode || sepayId}`)
        .limit(1);

      if (existing && existing.length > 0) {
        console.log("[WEBHOOK] Transaction already exists, skipping");
        return new Response(
          JSON.stringify({ success: true, message: "Already processed" }),
          { status: 200 }
        );
      }

      const { error: txError } = await supabase.from("transactions").insert({
        user_id: userId,
        wallet_id: walletId,
        type: transactionType,
        amount: amount,
        note: `[SePay] ${content || description || "Giao dịch ngân hàng"}`,
        date: transactionDate || new Date().toISOString(),
        created_at: new Date().toISOString(),
      });

      if (txError) {
        console.error("[WEBHOOK] Insert transaction error:", txError);
      } else {
        console.log(
          `[WEBHOOK] Created ${transactionType} transaction: ${amount}`
        );
      }

      // ================= UPDATE WALLET BALANCE =================
      const { data: wallet } = await supabase
        .from("wallets")
        .select("balance")
        .eq("id", walletId)
        .single();

      if (wallet) {
        const currentBalance = wallet.balance || 0;
        const newBalance =
          transactionType === "income"
            ? currentBalance + amount
            : currentBalance - amount;

        await supabase
          .from("wallets")
          .update({ balance: newBalance })
          .eq("id", walletId);

        console.log(
          `[WEBHOOK] Updated wallet balance: ${currentBalance} → ${newBalance}`
        );
      }
    }

    // ================= LOG WEBHOOK EVENT (optional) =================
    try {
      await supabase.from("webhook_logs").insert({
        user_id: userId,
        source: "sepay",
        event_type: transferType,
        payload: body,
        created_at: new Date().toISOString(),
      });
    } catch (_) {
      // Bảng webhook_logs chưa tồn tại → bỏ qua, không crash
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Processed ${transactionType} of ${amount}`,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[WEBHOOK] Error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
    });
  }
});
