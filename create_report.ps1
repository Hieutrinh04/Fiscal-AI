$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()
$sel = $word.Selection

# Title
$sel.Style = "Heading 1"
$sel.TypeText("BAO CAO VIBE CODING - FISCAL AI WALLET")
$sel.TypeParagraph()

$sel.Style = "Normal"
$sel.TypeText("Du an: Fiscal AI Wallet - Ung dung quan ly tai chinh ca nhan")
$sel.TypeParagraph()
$sel.TypeText("Cong nghe: Flutter, Supabase, Gemini AI, SePay")
$sel.TypeParagraph()
$sel.TypeParagraph()

# Table header
$table = $doc.Tables.Add($sel.Range, 13, 6)
$table.Style = "Table Grid"
$table.AllowAutoFit = $true

$headers = @("Mang ky thuat", "AI su dung", "Muc dich", "Phan AI sinh", "Phan SV chinh sua / dong gop", "Nhan xet (Hieu qua/Kho khan)")
for ($col = 1; $col -le 6; $col++) {
    $cell = $table.Cell(1, $col)
    $cell.Range.Text = $headers[$col - 1]
    $cell.Range.Font.Bold = $true
    $cell.Range.Font.Size = 10
    $cell.Shading.BackgroundPatternColor = -721354752  # light blue
}

$rows = @(
    @(
        "Xac thuc nguoi dung (Auth)",
        "Windsurf / Cascade AI",
        "Tao he thong dang nhap, dang ky, quan ly phien lam viec",
        "Toan bo AuthProvider, AuthService, LoginScreen, RegisterScreen; logic Supabase Auth, token refresh, guard route",
        "Chinh sua UI dang nhap cho phu hop thuong hieu; them validation tieng Viet; dieu chinh flow chuyen man hinh sau login",
        "Hieu qua cao: AI sinh code chuan Supabase Auth. Kho khan: can chinh lai UX flow cho hop voi nguoi dung Viet"
    ),
    @(
        "Quan ly Vi tien (Wallet)",
        "Windsurf / Cascade AI",
        "CRUD vi tien, tinh tong so du, cap nhat so du sau moi giao dich",
        "WalletProvider, WalletService, WalletScreen; logic cap nhat balance khi them/xoa giao dich; Realtime subscription",
        "Them icon emoji cho vi; chinh sua UI card vi; bo sung validation ten vi trung lap",
        "Hieu qua: AI hieu ro pattern Provider + Supabase. Kho khan: phai chinh logic dong bo so du sau giao dich nhieu lan"
    ),
    @(
        "Giao dich (Transaction)",
        "Windsurf / Cascade AI",
        "Them/sua/xoa giao dich, loc theo loai/ngay/danh muc, thong ke",
        "TransactionProvider (500+ dong), TransactionService, TransactionScreen; filter, sort, pagination; dailyTotals, categoryTotals",
        "Them tinh nang loc theo khoang thoi gian tu chon; chinh sua hien thi ngay gio tieng Viet; them swipe-to-delete",
        "Hieu qua rat cao: logic phuc tap duoc AI xu ly tot. Kho khan: bug so du vi sau khi xoa giao dich - phai debug thu cong"
    ),
    @(
        "Ngan sach (Budget)",
        "Windsurf / Cascade AI",
        "Dat ngan sach theo danh muc/thang, canh bao vuot muc",
        "BudgetProvider, BudgetService, BudgetScreen; tinh progress, isOverBudget, overBudgetList; chart progress bar",
        "Them mau sac canh bao do/vang/xanh theo muc do; chinh sua cach hien % da dung; them note cho tung ngan sach",
        "Hieu qua kha: AI sinh dung mo hinh du lieu. Kho khan: viec tinh spent theo thang thuc te can them logic rieng"
    ),
    @(
        "Muc tieu tiet kiem (Goal)",
        "Windsurf / Cascade AI",
        "Tao muc tieu, nap tien vao muc tieu, theo doi tien do",
        "GoalProvider, GoalService, GoalsScreen; addAmount, progress calculation; dialog nap tien tach biet async logic",
        "Fix bug UI freeze khi bam nap tien (Flutter Web mouse_tracker); chuyen tu showModalBottomSheet sang showDialog; tach _DepositSheet widget rieng",
        "Kho khan lon: Flutter Web 3.0.0 co bug overlay/mouse_tracker khi dung modal. Phai debug nhieu lan va thay doi kien truc dialog"
    ),
    @(
        "Lien ket ngan hang (Bank - SePay)",
        "Windsurf / Cascade AI",
        "Ket noi tai khoan ngan hang MSB qua SePay, tu dong dong bo giao dich",
        "BankProvider, BankService (300+ dong), sepay-webhook Edge Function, sepay-proxy Edge Function; polling 30s, sync logic",
        "Cau hinh SePay API key, VA number; test webhook voi du lieu that; chinh sua logic tranh trung giao dich khi sync",
        "Hieu qua: AI sinh duoc luong tich hop phuc tap. Kho khan: giao dich chuyen khoan thuong khong hien thi (chi hoat dong qua VA/QR)"
    ),
    @(
        "AI Chat (Gemini)",
        "Windsurf / Cascade AI + Gemini 1.5 Flash",
        "Tro chuyen voi AI ve tai chinh ca nhan, tu van chi tieu, tiet kiem",
        "AiService (sendChatMessage, getChatHistory), AiProvider, AIChatScreen; prompt engineering voi context tai chinh; luu lich su DB",
        "Them goi y cau hoi; chinh sua prompt tieng Viet; them tinh nang xoa lich su; fix bug load history (expand 1 row thanh 2 messages)",
        "Hieu qua cao: Gemini tra loi chat luong. Kho khan: gioi han rate limit Gemini free tier (429 error); can xu ly retry"
    ),
    @(
        "AI Insights & Phan tich",
        "Windsurf / Cascade AI + Gemini 1.5 Flash",
        "Tu dong phan tich chi tieu, dua ra loi khuyen tai chinh ca nhan hoa",
        "AiService (getInsights, getSavedInsights), AiProvider; JSON parsing tu Gemini; luu insight vao DB, cache tranh goi lai",
        "Chinh sua prompt de insight ngan gon hon; them logic chi goi Gemini 1 lan/session (insightsLoaded flag); hien thi dep tren HomeScreen",
        "Hieu qua: Gemini phan tich du lieu tai chinh tot. Kho khan: response format khong on dinh, phai them fallback JSON parsing"
    ),
    @(
        "Quy chung nhom (Shared Fund)",
        "Windsurf / Cascade AI",
        "Tao quy, moi thanh vien, quan ly dong gop nhom, phan quyen",
        "SharedFundProvider, SharedFundService (400+ dong), CreateFundScreen, FundDetailScreen; roles (owner/member), invitations",
        "Chinh sua UI danh sach thanh vien; them xac nhan truoc khi xoa quy; dieu chinh logic moi thanh vien qua user ID",
        "Hieu qua: AI xu ly logic nhieu nguoi dung tot. Kho khan: phong quyen (RLS) Supabase can cau hinh thu cong tren dashboard"
    ),
    @(
        "Thong ke & Bieu do",
        "Windsurf / Cascade AI",
        "Hien thi thong ke chi tieu/thu nhap theo tuan/thang/nam, bieu do cot, pie chart",
        "StatisticsScreen (1400+ dong), fl_chart library; dailyTotals, categoryTotals, monthlyTotals; animation, calendar grid",
        "Fix bug tab Tuan/Nam khong loc du lieu theo ky (them range-filtered methods); them bieu do 7 cot cho Tuan, 12 cot cho Nam; them dieu huong ky truoc/sau",
        "Hieu qua: AI sinh bieu do dep va co animation. Kho khan: ban dau selectedTab chi doi label, khong loc du lieu - phai them toan bo range filtering logic"
    ),
    @(
        "Thong bao (Notification)",
        "Windsurf / Cascade AI",
        "Canh bao so du thap, chi tieu lon, so du am, vuot ngan sach",
        "NotificationProvider, NotificationService, NotificationScreen; 4 loai canh bao tu dong sau moi giao dich chi tieu",
        "Dieu chinh nguong canh bao (500k chi tieu lon, 50k so du thap); chinh sua noi dung thong bao tieng Viet; them badge count tren icon",
        "Hieu qua: He thong canh bao hoat dong tot. Kho khan: canh bao co the qua nhieu neu giao dich lien tuc - can them cooldown"
    ),
    @(
        "Lich su Chat AI",
        "Windsurf / Cascade AI",
        "Luu va hien thi lai lich su tro chuyen voi AI nhom theo ngay",
        "AiChatHistoryScreen moi (tao tu dau); getChatHistory, deleteAllChatHistory trong service; nhom theo ngay, xem chi tiet cuoc hoi thoai",
        "Thiet ke toan bo UI history screen; quyet dinh cach nhom (theo ngay); them DraggableScrollableSheet xem chi tiet; fix bug expand rows",
        "Hieu qua: AI sinh component nhanh. Kho khan: cau truc DB luu 1 row = 1 cap (user+AI) nen phai xu ly expand khi hien thi"
    )
)

for ($row = 0; $row -lt $rows.Length; $row++) {
    for ($col = 0; $col -lt 6; $col++) {
        $cell = $table.Cell($row + 2, $col + 1)
        $cell.Range.Text = $rows[$row][$col]
        $cell.Range.Font.Size = 9
    }
}

# Auto fit
$table.Columns.AutoFit()

$outputPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop", "VibeCoding_FiscalAI.docx")
$doc.SaveAs([ref]$outputPath, [ref]16)  # 16 = wdFormatDocx
$doc.Close()
$word.Quit()

Write-Host "File da duoc luu tai: $outputPath"
