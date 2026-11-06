#!/usr/bin/env python3
"""
Compose App Store screenshots (device frame + Thai headline on a green gradient)
from raw simulator captures. Uses only the Python stdlib + headless Google Chrome
(Chrome renders Thai text correctly, which Pillow without libraqm does not).

Usage:
  python3 docs/imageApp/tools/make_store_screenshots.py            # iPhone 6.9" (1320x2868)
  python3 docs/imageApp/tools/make_store_screenshots.py --ipad     # iPad 13"   (2064x2752)
  python3 docs/imageApp/tools/make_store_screenshots.py --android  # Google Play phone (1320x2600, 8 slides)
  ... [raw_name ...]  to render only some slides

Input : docs/imageApp/raw_ios_6_9/<name>.png  | raw_ipad_13/<name>.png  (raw simulator screenshots)
Output: docs/imageApp/ios_6_9_new/NN_<name>.png | ipad_13_new/NN_<name>.png
"""
import pathlib
import subprocess
import sys
import tempfile
import urllib.parse

ROOT = pathlib.Path(__file__).resolve().parents[3]
RAW = ROOT / "docs/imageApp/raw_ios_6_9"
OUT = ROOT / "docs/imageApp/ios_6_9_new"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
IPAD = "--ipad" in sys.argv
ANDROID = "--android" in sys.argv
if ANDROID:
    sys.argv.remove("--android")
if IPAD:
    sys.argv.remove("--ipad")
    RAW = ROOT / "docs/imageApp/raw_ipad_13"
    OUT = ROOT / "docs/imageApp/ipad_13_new"
    W, H = 2064, 2752
    # zoom for the text block, phone/tablet frame geometry
    Z, PW, PT, BZ, RO, RI = 1.2, 1640, 740, 30, 78, 52
else:
    W, H = 1320, 2868
    Z, PW, PT, BZ, RO, RI = 1.0, 1096, 750, 24, 150, 126
    if ANDROID:
        # Google Play phone screenshots: 1320x2600 (<= 2:1), max 8 images
        H = 2600
        RAW = ROOT / "docs/imageApp/raw_android"   # real Android emulator captures (1080x2400)
        RO, RI = 96, 72   # Android status bar sits at the far left: keep the screen corners tight so the clock is not clipped
        OUT = ROOT / "docs/imageApp/android_new"
ANDROID_SLIDES = ["p0_welcome", "p2_map", "p1_areas", "c1_dashboard", "c3_services", "c5_pollution_list", "c6_pollution_map", "a1_dashboard"]
IPAD_SLIDES = {"p0_welcome", "p2_map", "p3_summary", "p1_areas", "c1_dashboard", "c3_services", "c4_quarterly", "c5_pollution_list", "c6_pollution_map"}

# (raw file, role chip, role colour, headline (use <em> for the highlighted words), sub-headline)
SLIDES = [
    ("p0_welcome", "เริ่มต้นใช้งาน", "#7fe3a6", "เลือกบทบาท<br><em>ที่ใช่สำหรับคุณ</em>", "ผู้ใช้ทั่วไป ชุมชน หรือผู้ดูแลระบบ"),
    ("p2_map", "ผู้ใช้ทั่วไป", "#7fe3a6", "ป่าชายเลน<em>ภาคตะวันออก</em><br>ครบในแผนที่เดียว", "กรองตามสถานะความสมบูรณ์ของพื้นที่"),
    ("p3_summary", "ผู้ใช้ทั่วไป", "#7fe3a6", "สรุป<em>บริการระบบนิเวศ</em><br>ย้อนหลัง 12 เดือน", "จำนวนบริการ ผู้รับประโยชน์ และมูลค่า รายเดือน"),
    ("p1_areas", "ผู้ใช้ทั่วไป", "#7fe3a6", "ค้นหา<em>พื้นที่ป่าชายเลน</em><br>ดูสถิติในหน้าเดียว", "ชนิดพันธุ์ ขนาดพื้นที่ และชุมชนผู้ดูแล"),
    ("c1_dashboard", "ชุมชน", "#ffc46b", "ชุมชน<em>บริหารข้อมูล</em><br>ได้ในแอปเดียว", "ข้อมูลชุมชน บริการนิเวศ และรายงาน"),
    ("c3_services", "ชุมชน", "#ffc46b", "บันทึก<em>บริการทางนิเวศ</em><br>ทั้งทรัพยากรและกิจกรรม", "เห็นมูลค่ารวมทันทีที่บันทึก"),
    ("c4_quarterly", "ชุมชน", "#ffc46b", "<em>รายงานรายไตรมาส</em><br>อ่านง่าย เห็นภาพรวม", "มูลค่าเศรษฐกิจ ผู้รับประโยชน์ แยกตามหมวดหมู่"),
    ("c5_pollution_list", "ชุมชน", "#ffc46b", "แจ้ง<em>แหล่งมลพิษ</em><br>ติดตามสถานะได้ทันที", "แยกตามประเภทและระดับความรุนแรง"),
    ("c6_pollution_map", "ชุมชน", "#ffc46b", "ปักหมุดมลพิษ<br>บน<em>แผนที่จริง</em>", "รู้ตำแหน่งชัดเจน ส่งต่อให้หน่วยงานได้เร็ว"),
    ("a1_dashboard", "ผู้ดูแลระบบ", "#8fd3ff", "ผู้ดูแลระบบ<br>เห็น<em>ภาพรวมทั้งระบบ</em>", "ชุมชน พื้นที่ป่า และรายงานมลพิษ"),
    ("a2_approvals", "ผู้ดูแลระบบ", "#8fd3ff", "<em>อนุมัติชุมชนใหม่</em><br>ได้ในไม่กี่ขั้นตอน", "ตรวจสอบข้อมูลแล้วตัดสินใจได้ทันที"),
]

HTML = """<!doctype html>
<html lang="th"><head><meta charset="utf-8">
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  html,body{width:%(W)dpx;height:%(H)dpx;overflow:hidden}
  body{font-family:"Sukhumvit Set","Thonburi","Noto Sans Thai",sans-serif;color:#fff;position:relative;
       background:
         radial-gradient(1200px 900px at 90%% 8%%, rgba(120,230,160,.35), transparent 60%%),
         radial-gradient(1100px 900px at -10%% 55%%, rgba(40,160,110,.35), transparent 60%%),
         linear-gradient(165deg,#0b3a2c 0%%,#12603f 52%%,#1f8a52 100%%);}
  .leaf{position:absolute;right:-230px;top:-190px;width:900px;height:900px;opacity:.07;transform:rotate(18deg)}
  .root{position:absolute;left:0;right:0;bottom:0;height:620px;
        background:radial-gradient(900px 300px at 50%% 100%%, rgba(0,0,0,.35), transparent 70%%)}
  .copy{position:absolute;left:%(cl)dpx;right:%(cl)dpx;top:%(ct)dpx;zoom:%(z)s}
  .chip{display:inline-flex;align-items:center;gap:16px;padding:14px 34px 14px 26px;border-radius:999px;
        background:rgba(255,255,255,.14);border:2px solid rgba(255,255,255,.25);
        font-size:44px;font-weight:600;letter-spacing:.5px;color:#fff}
  .chip i{display:block;width:22px;height:22px;border-radius:50%%;background:%(accent)s;box-shadow:0 0 0 8px rgba(255,255,255,.12)}
  h1{margin-top:44px;font-size:100px;line-height:1.22;font-weight:700;letter-spacing:-.5px;text-shadow:0 6px 30px rgba(0,0,0,.25)}
  h1 em{font-style:normal;color:%(accent)s}
  p.sub{margin-top:26px;font-size:50px;line-height:1.35;color:rgba(255,255,255,.84);font-weight:400}
  .phone{position:absolute;left:%(pl)dpx;top:%(pt)dpx;width:%(pw)dpx;padding:%(bz)dpx;border-radius:%(ro)dpx;
         background:linear-gradient(145deg,#4a4a4d 0%%,#161618 40%%,#050506 100%%);
         box-shadow:0 0 0 3px #6a6a6e inset, 0 90px 140px rgba(0,0,0,.5), 0 30px 60px rgba(0,0,0,.35)}
  .phone .btn{position:absolute;width:10px;background:#2b2b2e;border-radius:6px}
  .screen{border-radius:%(ri)dpx;overflow:hidden;background:#fff;line-height:0}
  .screen img{width:100%%;display:block}
  .shine{position:absolute;inset:%(bz)dpx;border-radius:%(ri)dpx;pointer-events:none;
         background:linear-gradient(115deg,rgba(255,255,255,.10) 0%%,rgba(255,255,255,0) 28%%)}
</style></head><body>
  <svg class="leaf" viewBox="0 0 100 100"><path fill="#fff" d="M82 6C45 8 14 28 14 62c0 12 6 22 14 28 2-18 12-34 30-46-12 12-20 26-24 44 6 2 12 2 18 0C86 80 90 36 82 6z"/></svg>
  <div class="root"></div>
  <div class="copy">
    <div class="chip"><i></i>%(chip)s</div>
    <h1>%(headline)s</h1>
    <p class="sub">%(sub)s</p>
  </div>
  <div class="phone">
    <span class="btn" style="left:-8px;top:300px;height:70px"></span>
    <span class="btn" style="left:-8px;top:430px;height:140px"></span>
    <span class="btn" style="left:-8px;top:610px;height:140px"></span>
    <span class="btn" style="right:-8px;top:480px;height:210px"></span>
    <div class="screen"><img src="%(img)s"></div>
    <div class="shine"></div>
  </div>
</body></html>"""


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    only = set(sys.argv[1:])
    with tempfile.TemporaryDirectory() as tmp:
        for i, (name, chip, accent, headline, sub) in enumerate(SLIDES, 1):
            if only and name not in only:
                continue
            src = RAW / f"{name}.png"
            if not src.exists():
                print("skip (missing raw):", name)
                continue
            if IPAD and name not in IPAD_SLIDES:
                continue
            if ANDROID and name not in ANDROID_SLIDES:
                continue
            pw, bz = PW, BZ
            html = HTML % dict(
                W=W, H=H, accent=accent, chip=chip, headline=headline, sub=sub,
                img="file://" + urllib.parse.quote(str(src)),
                pl=(W - pw) // 2, pt=PT, pw=pw, bz=bz, ro=RO, ri=RI,
                z=Z, cl=int(96 * (1.6 if IPAD else 1) / Z), ct=int((130 if not IPAD else 110) / Z),
            )
            page = pathlib.Path(tmp) / f"{name}.html"
            page.write_text(html, encoding="utf-8")
            n = ANDROID_SLIDES.index(name) + 1 if ANDROID else i
            out = OUT / f"{n:02d}_{name}.png"
            subprocess.run([
                CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--force-device-scale-factor=1", f"--window-size={W},{H}",
                "--allow-file-access-from-files", "--virtual-time-budget=4000",
                f"--screenshot={out}", "file://" + urllib.parse.quote(str(page)),
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("wrote", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
