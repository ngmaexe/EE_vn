from docx import Document
import re
import html
from pathlib import Path

# ================================
# Cấu hình file
# ================================

INPUT_FILE = "BG_TỔNG HỢP_BẢN THẢO.docx"
OUTPUT_FILE = "bhagavad-gita.html"
CSS_PATH = "./Assets/styles.css"
JS_PATH = "./js/verse.js"

# ================================
# Đọc file Word
# ================================

doc = Document(INPUT_FILE)

lines = []

for p in doc.paragraphs:
    text = p.text.strip()
    if text:
        lines.append(text)

# ================================
# Hàm hỗ trợ
# ================================

def make_id_from_verse(verse_number):
    """
    Ví dụ:
    1.1 -> ch1-1
    2.15 -> ch2-15
    """
    return "ch" + verse_number.replace(".", "-")


def is_chapter(line):
    return line.strip().upper().startswith("CHƯƠNG")


def is_verse(line):
    return re.match(r"^Câu\s+([\d\.]+)", line.strip())


def close_verse(html_parts, is_open):
    if is_open:
        html_parts.append("    </div>")
        html_parts.append("  </div>")
    return False


# ================================
# Tạo HTML
# ================================

html_parts = []

html_parts.append("""<!doctype html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Bhagavan Giita</title>
  <link rel="stylesheet" href="./Assets/styles.css">
</head>
<body>
""")

verse_is_open = False
verse_count = 0
chapter_count = 0
in_preface = False

for line in lines:
    safe_line = html.escape(line)

    # Tên sách
    if line.upper() == "BHAGAVAN GIITA":
        html_parts.append(f'  <div class="book_title">{safe_line}</div>')
        continue

    if line.upper() == "BÀI CA CỦA ĐẤNG TỐI CAO":
        html_parts.append(f'  <div class="book_subtitle">{safe_line}</div>')
        continue

    # Tác giả / biên soạn
    if line.startswith("Biên soạn"):
        html_parts.append(f'  <p class="book_author">{safe_line}</p>')
        continue

    # Lời nói đầu
    if line.upper() == "LỜI NÓI ĐẦU":
        verse_is_open = close_verse(html_parts, verse_is_open)
        in_preface = True
        html_parts.append('  <div class="book_chapter_title" id="ch0">LỜI NÓI ĐẦU</div>')
        continue

    # Chương
    if is_chapter(line):
        verse_is_open = close_verse(html_parts, verse_is_open)
        in_preface = False
        chapter_count += 1
        html_parts.append(f'  <div class="book_chapter_title" id="chapter-{chapter_count}">{safe_line}</div>')
        continue

    # Câu
    verse_match = is_verse(line)
    if verse_match:
        verse_is_open = close_verse(html_parts, verse_is_open)

        verse_count += 1
        verse_number = verse_match.group(1)
        verse_id = make_id_from_verse(verse_number)

        html_parts.append(f'  <div class="verse-item" id="{verse_id}">')
        html_parts.append('    <button class="verse-toggle" type="button">')
        html_parts.append(f'      <span class="verse-title">Câu {html.escape(verse_number)}</span>')
        html_parts.append('      <span class="verse-icon">+</span>')
        html_parts.append('    </button>')
        html_parts.append('    <div class="verse-content">')
        html_parts.append('      <div class="verse-image-wrap">')
        html_parts.append('        <img')
        html_parts.append('          class="verse-image"')
        html_parts.append(f'          src="../Assets/img/bhagavad/{html.escape(verse_number)}.svg"')
        html_parts.append(f'          alt="Câu {html.escape(verse_number)}"')
        html_parts.append('        />')
        html_parts.append('      </div>')

        verse_is_open = True
        continue

    # Từ đồng nghĩa
    if line.startswith("Từ đồng nghĩa:"):
        content = line.replace("Từ đồng nghĩa:", "", 1).strip()
        html_parts.append('      <p class="synonym-line">')
        html_parts.append('        <span class="verse-label">Từ đồng nghĩa:</span>')
        html_parts.append(f'        <span class="synonym-text">{html.escape(content)}</span>')
        html_parts.append('      </p>')
        continue

    # Ý nghĩa
    if line.startswith("Ý nghĩa:"):
        content = line.replace("Ý nghĩa:", "", 1).strip()
        html_parts.append('      <p class="meaning-line">')
        html_parts.append('        <span class="verse-label">Ý nghĩa:</span>')
        html_parts.append(f'        <span class="meaning-text">{html.escape(content)}</span>')
        html_parts.append('      </p>')
        continue

    # Diễn giải
    if line.startswith("Diễn giải:"):
        content = line.replace("Diễn giải:", "", 1).strip()
        html_parts.append('      <p class="minor_heading">Diễn giải:</p>')

        if content:
            html_parts.append(f'      <p class="paragraph">{html.escape(content)}</p>')
        continue

    # Đoạn thường
    html_parts.append(f'      <p class="paragraph">{safe_line}</p>' if verse_is_open else f'  <p class="paragraph">{safe_line}</p>')

# Đóng câu cuối cùng nếu còn mở
verse_is_open = close_verse(html_parts, verse_is_open)

html_parts.append("""
  <script src="./js/verse.js"></script>
</body>
</html>
""")

# ================================
# Ghi file HTML
# ================================

Path(OUTPUT_FILE).write_text("\n".join(html_parts), encoding="utf-8")

print("Đã chuyển xong.")
print(f"Tổng số câu đã nhận diện: {verse_count}")
print(f"Tổng số chương đã nhận diện: {chapter_count}")
print(f"File HTML đã tạo: {OUTPUT_FILE}")