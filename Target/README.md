# Target - AVCM Golden 檔案

此目錄存放 FullTest 逐案比對用的 golden 輸出（對應 `Output/` 同名檔）。
每個檔案的產出來源與版本記錄如下；重建時務必更新本檔。

## 2026-10-24 重建（H3 全部 160 案）

- **來源**：Gazelle 引擎（commit `cc49ac6`；引擎 libs 自 2026-10-16 起未更動）於 WSL（Ubuntu-26.04、g++-13）跑 FullTest 的 `Output/` 產出，經 lcms 交叉驗證後升格為 golden。
- **驗證工具**：`apps/ICC_Test/lcms_check.cpp`（Gazelle repo）——同一輸入與 ICC 檔經 lcms2 2.19（Little-CMS 源碼自建，intent Perceptual）轉換後，與引擎輸出逐像素比對；Lab 直接算 dE76，CMYK 經輸出 profile 的 A2B 換算 dE76。注意 Tiff_STL4 需以 `-DFIXED_VECTOR` 編譯（類別佈局一致）。
- **驗證結果（12 代表案，涵蓋全部 9 個超標案）**：
  - Lab 輸出：dE76 mean 0.592–1.155、max 3.19–9.94
  - CMYK 輸出：dE76 mean 0.382–1.231、max 3.04–7.94
  - 判定：通過（兩獨立 CMM 實作的合理差異範圍，mean dE < 1.3）。
- **效果**：快照（Gazelle `tests/golden/fulltest_errors.txt`）160 案全部 Total Error 0；原 AVE>1000 的 9 個 RGB→8-bit 案全部歸零。
- **未以 lcms 驗證**：CLR6/CLR7 多色案維持升格自現行引擎輸出（lcms 多通道對照未做）；M* matrix-shaper 16 案與引擎 byte-exact、未變。
- **重現程序**：Gazelle repo 的 `apps/ICC_Test/lcms_check.cpp` 與 `GenFullRange.cpp` 檔頭註解；流程記錄於 `Test_AVCM.md`。

## 2026-10-24（同日）Lab 編碼改為 ICC v4

- 36 個 Lab 相關 golden 改以 ICC v4 PCS 編碼重產：Lab8 L=L×2.55、a/b=a+128；Lab16 L=L×65535/100、a/b=(a+128)×257（引擎程式變更見 Gazelle commit）。
- `Input/IT8_Lab.tif`、`IT8_Lab16.tif`、`Lab100.tif` 以 `LabReencode.cpp` 同步重編碼；其餘 124 案未受影響；快照維持全零 160 行。
- 舊 signed（無偏移）編碼的 Lab 檔自此不再被支援；與 lcms TYPE_Lab_8/16 直接互通（驗證 dE 見 `Test_AVCM.md`）。

## 歷史

- M*（matrix-shaper）16 案：2026-10-14 由現行引擎產出（data repo commit `824d191`）。
- V2V2/V2V4/V4V2/V4V4 系列：JohnXu28/IccTestFiles 早期產出（確切工具已無記錄），2026-10-24 起由 H3 重建取代（同日晚改為 ICC v4 Lab 編碼）。
