from zipfile import ZipFile
from pathlib import Path
import shutil

INPUT_DOCX = r"C:\Users\s8218714\EE_vn\bhagavad\BG_TỔNG HỢP_BẢN THẢO.docx"
OUTPUT_DIR = Path("Assets/img/bhagavad")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

with ZipFile(INPUT_DOCX, "r") as docx:
    media_files = [
        file for file in docx.namelist()
        if file.startswith("word/media/")
    ]

    for index, media_file in enumerate(media_files, start=1):
        original_name = Path(media_file).name
        extension = Path(original_name).suffix

        output_name = f"image-{index}{extension}"
        output_path = OUTPUT_DIR / output_name

        with docx.open(media_file) as source, open(output_path, "wb") as target:
            shutil.copyfileobj(source, target)

        print(f"Đã xuất: {output_path}")

print("Hoàn tất xuất ảnh.")