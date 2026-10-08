"""Rasterize the original geometric Nurturio sprout mark into native icon slots."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
root=Path('apps/mobile')
def icon(size):
    image=Image.new('RGB',(size,size),'#FFF8EB')
    draw=ImageDraw.Draw(image)
    scale=size/512
    def points(coords): return [(int(x*scale),int(y*scale)) for x,y in coords]
    draw.rounded_rectangle(tuple(int(v*scale) for v in (235,230,277,410)),radius=int(21*scale),fill='#456A43')
    draw.polygon(points([(254,280),(190,277),(132,240),(105,187),(97,135),(151,140),(204,165),(239,207)]),fill='#456A43')
    draw.polygon(points([(256,238),(272,183),(309,144),(355,126),(417,124),(406,183),(373,225),(325,247),(279,252)]),fill='#6E9661')
    draw.ellipse(tuple(int(v*scale) for v in (339,75,386,122)),fill='#EDAE45')
    return image
android={'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}
for density,size in android.items():
    icon(size).save(root/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
ios=root/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
contents=json.loads((ios/'Contents.json').read_text())
for slot in contents['images']:
    if slot.get('filename'):
        size=int(float(slot['size'].split('x')[0])*float(slot['scale'].rstrip('x')))
        icon(size).save(ios/slot['filename'])
for size in (192,512):
    for prefix in ('Icon-','Icon-maskable-'):
        icon(size).save(root/f'web/icons/{prefix}{size}.png')
icon(32).save(root/'web/favicon.png')
print('Nurturio sprout icons created for iOS, Android and web.')
