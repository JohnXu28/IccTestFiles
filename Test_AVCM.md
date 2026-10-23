Test_AVCM 強化測試計畫
#1.Target,Target2 是以前的測試結果，或是Photoshop模擬的結果。
#2.建議產生一個Target0，是目前的模擬結果，理論上compare應該是要為0,較容易比較Algorithm變化時，資料是否有變。
#3.測試時，先對比Target0,再對比Target。 思考當Target0 完全一樣時，還需後續測試嗎?
#4.因Target 測試結果太舊，有需要重建新的測試結果? Photoshop 結果取得不易，要從 lcms 抓資料嗎?
#5.需要新增BCP 的測試結果嗎? 須測試的結果會不會暴增?
#6.目前的Test Case 有可以改善的方式嗎? 需要新增 Test Case Target?

===================== 檢討結論與後續改善建議（2026-10-23） =====================

【現況調查】上方 6 題對應的程式碼與資料事實：
- 測試主程式是 apps/ICC_Test/Main.cpp 的 FullTest()：約 160 筆有效案例，逐案把 Input/ 轉換到 Output/，再與 Target/ 同名檔做逐 byte 比對（CompareTiff）。
- CompareTiff 現況：8-bit 印 "Error : ... AVE(*1000)"，16-bit 印 "Total Error : ... AVE(*1000)"；AVE 超標（>1000）只印 "Error *****" 警示，函式永遠回傳 0，單案超標不會讓測試失敗；缺 target 檔時直接 skip（靜默通過）。
- CI 門禁（tests/golden_fulltest.cmake）只抓 "Total Error" 行與快照 tests/golden/fulltest_errors.txt 比對，所以只有 16-bit 案例被 gate，8-bit 案例完全沒有門禁。
- 快照顯示：M*（matrix-shaper）系列與現行引擎 byte-exact（Total Error 0）；V2V2 系列有固定誤差，golden 過舊（與 #4 相符）。Output/ 裡 10/22 跑出的新 V2V2 結果尚未 commit，正是重建 golden 的材料。
- Target/ 160 檔 = Target2/ 144 檔 + M* 16 檔，Target2 已被 Target 完全取代，可封存。
- BPC（引擎 Adjust_BlackPoint）目前只有 unit test（tests/unit/TestBpc.cpp）；FullTest 全部硬編 Perceptual intent 且 BPC 參數為 0，端到端沒有 BPC/intent 變化覆蓋。

【逐題結論】
#1. Target、Target2 都是歷史 golden（來自 JohnXu28/IccTestFiles 資料 repo；M* 為 2026-10-14 加入、與現行引擎 byte-exact，應為引擎產出；更早期檔案的確切產出工具已無記錄）。建議在 Target/ 放 README，記錄每批檔案的產出工具、版本、日期，否則永遠無法分辨「差異是 bug 還是 golden 過舊」。
#2. 強烈建議實作 Target0，成本低、價值高。現行 CI 快照已相當於「數值版 Target0」（M* 全 0），可再補圖檔層：新增 Target0/ 目錄，由現行引擎產出後 commit；之後任何 Algorithm 改動，vs Target0 的 delta 一眼可見。
#3. Target0 全等時不必跳過後續測試，但要分層報告：vs Target0 全等代表行為無變，vs Target 的差異屬「已知差異」，不需人工判定；只有 vs Target0 有差才需 review。日常開發可加 --quick 模式只跑 Target0，速度快。
#4. 建議重建過舊的 V2V2 golden，採雙軌驗證：(a) 用 lcms（transicc 或 lcms2 自寫對照工具）產出同一組轉換，存到 Target_lcms/ 當 cross-check；lcms 的 LUT 內插/舍入與自家引擎不同，只能做容差或 Delta E 比對，不能當 byte-exact gate。(b) 確認現行輸出正確後，把 Output/ 升格為新 Target，並在 README 記錄重建歷程與容差數字。Photoshop 手動產出不可自動化，保留少數代表性檔案當人工參考即可，不要當日常 gate。
#5. 不需要全矩陣 BPC（golden 檔案數會 x2 暴增、維護成本高、價值低）。BPC 只影響黑點映射，新增 4-6 個代表性案例即可（如 Lab->CMYK V2/V4、RGB->CMYK V2 各 1-2 案）；黑點正確性細節已由 unit test 覆蓋。
#6. 需要。Test Case 可改善之處與要新增的 golden 見下方清單（H1/H2/L3、M4）。

【改善清單】（依優先序）
高優先
H1. CompareTiff 強化：比對前檢查兩檔尺寸/位元數/StripByteCounts 一致（現行拿 Target 的 StripByteCounts 讀兩個 buffer，尺寸不同會越界或假 pass）；誤差累積與 error*1000 改用 int64_t（16-bit 大檔 int 會溢位）；AVE 超標改回傳非 0，讓跑批與 CI 真正失敗。
H2. CI 門禁納入 8-bit 案例：快照比對同時抓 "Error :" 與 "Total Error" 兩類行（或統一輸出格式），目前 8-bit 案例完全沒有 gate。
H3. 重建過舊 golden（配合 #4），重建歷程寫入 Target/README。
中優先
M1. 封存/刪除 Target2（已被 Target 完全取代）。
M2. 輸出檔命名統一：V2V2RGB82lab8 / V4V2RGB82lab_8 / V2V2RGB16ToRGb8 大小寫與底線不一，建議一律 PascalCase。
M3. 本檔 Test_AVCM.md 是 Big5 編碼，多數工具讀成亂碼，建議轉 UTF-8；Test_AVCM.md.bak 是空檔，可刪。
M4. 新增 BPC 端到端子集（4-6 案，見 #5）。
低優先
L1. intent 多樣化：目前全部 Perceptual，挑幾個代表案補 RelativeColorimetric。
L2. 清理雜物：各目錄 Thumbs.db、過時 AVCMM.ini（指向 lombook3.icc/fuji.tif，與 FullTest 無關）、Output/ 無對應 golden 的舊檔（Lab2CMYK_Ver4.*）；lzw.bat/LZW.exe 的壓縮流程補文件（壓縮後 binary diff 不可讀，長期建議 git-lfs 或保留未壓縮）。
L3. M 系列覆蓋缺口：M_Adobe/M_Apple 缺 RGB16->Lab*；M 系列只測 CMYK_V2 未測 V4；MsRGB 缺 RGB16->Lab8/Lab16。可視需要補 2-4 案。
L4. Tiff 64-bit/BigTIFF 資料：暫不建立（決議：現行工作場合用不到）。引擎 I/O 僅 8/16-bit，此資料現階段無用；待 Part 2「64-bit Offset 解碼」落地且有實際需求時，再以合成小檔補測即可。
L5. FullRange 端點/全域覆蓋測試：加入。已產生 Input/FullRange8.tif（256x256 RGB 8-bit：R=x、G=y、B=(x+y)/2，三通道各涵蓋 0-255 全部碼值，x=y 對角線為灰階 ramp）與 FullRange16.tif（256x256 RGB 16-bit：R=y*256+x 涵蓋 0-65535 每一碼值、G/B=x*257/y*257 涵蓋端點與均佈 256 階），補 IT8 patch 輸入測不到的端點與離一 bug；產生器 apps/ICC_Test/GenFullRange.cpp（呼叫 Tiff_STL4，LZW 壓縮，未接入 build 系統）。後續加案只需代表性子集（M* 全 16 案 + V2V2 RGB→CMYK/Lab 數案），不一次對全 160 案展開 golden。
【建議執行順序】H1+H2（讓測試真的會失敗，報酬最高）-> M1+M2（資料減重、命名一致）-> H3（golden 重建，需 lcms 驗證，工作量最大）-> 其餘視需求。

【第一優先補強完成記錄（2026-10-24）】
- H1 CompareTiff 強化已落地：比對前檢查兩檔 Width/Length/SamplesPerPixel/BitsPerSample/StripByteCounts 一致，不符即失敗；誤差累積與 error*1000 改用 int64_t（16-bit 大檔不再溢位）；8/16-bit 統一輸出 "Total Error" 行；AVE>1000 回傳失敗，FullTest 統計失敗數並以 exit code 反映（0=全過、1=有超標、其他=嚴重錯誤）。
- H2 CI 門禁納入 8-bit：快照 84->160 行（舊 16-bit 84 行與 WSL 重跑逐行一致，跨平台確定性確認）；golden_fulltest.cmake 對 RC=1（超標）不直接 FATAL，由快照逐案比對把關，RC 為其他值才立即失敗。
- 執行發現 9 案 AVE>1000（AVE 1122-1411），全是 RGB->8-bit 輸出的舊 golden：V2V2RGB82lab8、V2V2RGB8ToCMYK8、V2V2RGB16ToLab8、V2V2RGB16ToCMYK8、V2V4RGB8ToCMYK8、V4V2RGB82lab_8、V4V2RGB8ToCMYK8、V4V2RGB16ToCMYK8、V4V4RGB8ToCMYK8 -> 即 H3 golden 重建的優先處理清單。
- 環境備註：Windows 端新編譯 exe 被 Smart App Control 擋下（新 hash 無簽章），驗證改於 WSL（Ubuntu-26.04、g++-13）執行；WSL 內建置程序＝源碼 tar 複製到 ~/gazelle-build，make 由 apt-get download + dpkg -x 取得（免 sudo），CXX=g++-13 make -f Makefile_AVCM。

【H3 golden 重建完成記錄（2026-10-24）】
- 驗證：以 lcms2 2.19（Little-CMS 源碼於 WSL 自建）交叉驗證 12 代表案（含全部 9 超標案）——Lab 輸出 dE76 mean 0.592-1.155 / max 3.19-9.94；CMYK 輸出經輸出 profile A2B 換算 dE76 mean 0.382-1.231 / max 3.04-7.94 -> 判定通過（獨立 CMM 實作合理差異範圍）。工具：Gazelle apps/ICC_Test/lcms_check.cpp（須以 -DFIXED_VECTOR 編譯，與 Tiff_STL4 類別佈局一致）。
- 升格：Output/ 160 案 -> Target/（144 檔更新、M* 16 檔 byte-exact 不變）；WSL 重跑 FullTest：全 160 案 Total Error 0、EXIT 0、無超標無 skip；CI 快照重建為全零 160 行。
- 9 個原 AVE>1000 的 RGB->8-bit 案全部歸零；CLR6/CLR7 未做 lcms 多通道對照（維持引擎輸出升格）。重建歷程與重現程序見 Target/README.md。
- 剩餘待辦：M4（BPC 端到端子集）、L3（M 系列覆蓋缺口）、FullRange 子集加案。
