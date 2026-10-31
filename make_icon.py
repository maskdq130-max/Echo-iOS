# Рисует иконку приложения (круги-«эхо») и создаёт папку Assets.xcassets
import json, os
from PIL import Image, ImageDraw

d = "Assets.xcassets/AppIcon.appiconset"
os.makedirs(d, exist_ok=True)
json.dump({"info": {"author": "xcode", "version": 1}}, open("Assets.xcassets/Contents.json", "w"))
json.dump({
    "images": [{"filename": "icon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1},
}, open(d + "/Contents.json", "w"))

s = 1024
im = Image.new("RGB", (s, s), (0, 0, 0))
dr = ImageDraw.Draw(im)
c = s // 2
for r, col in [(430, (255, 255, 255)), (330, (0, 0, 0)), (230, (255, 255, 255)), (130, (0, 0, 0)), (50, (255, 255, 255))]:
    dr.ellipse((c - r, c - r, c + r, c + r), fill=col)
im.save(d + "/icon.png")
print("icon ok")
