import random, math
random.seed(7)
S=17.0; C=(410.0,630.0); th=math.radians(38)
u=(math.cos(th), -math.sin(th)); v=(math.sin(th), math.cos(th))
def P(x,y): return (C[0]+S*(x*u[0]+y*v[0]), C[1]+S*(x*u[1]+y*v[1]))
def path(pts, close=True):
    d='M'+' L'.join(f'{a:.1f} {b:.1f}' for a,b in (P(*p) for p in pts))
    return d+(' Z' if close else '')
body=path([(18,0),(-12,12),(-5,0),(-12,-12)])
crest=path([(10,0),(8,-3),(6,0),(4,-3),(2,0),(0,-3),(-2,0)], close=False)
def seg(x1,x2,w,color):
    a=P(x1,0); b=P(x2,0)
    return f'<line x1="{a[0]:.1f}" y1="{a[1]:.1f}" x2="{b[0]:.1f}" y2="{b[1]:.1f}" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>'
bg_=seg(22,28,32,'#ff1f8f')+seg(31,37,32,'#ff1f8f')
bl=seg(22,28,14,'#ffffff')+seg(31,37,14,'#ffffff')
sc=P(39.5,0); sparks=[]
for _ in range(24):
    ang=random.uniform(0,2*math.pi); r=random.uniform(12,68)
    sparks.append(f'<circle cx="{sc[0]+math.cos(ang)*r:.0f}" cy="{sc[1]+math.sin(ang)*r:.0f}" r="{random.uniform(3,8.5):.1f}" fill="{random.choice(["#26f2ff","#26f2ff","#ffffff"])}" opacity="{random.uniform(.55,1):.2f}"/>')
rain=[]; a=-math.pi/2-0.38
for _ in range(80):
    x=random.uniform(-100,1124); y=random.uniform(-100,1124); L=random.uniform(30,90)
    rain.append(f'<line x1="{x:.0f}" y1="{y:.0f}" x2="{x+math.cos(a)*L:.0f}" y2="{y-math.sin(a)*L:.0f}" stroke="#9fc0ff" stroke-opacity="{random.uniform(.08,.26):.2f}" stroke-width="{random.uniform(1.5,3):.1f}"/>')
F='filterUnits="userSpaceOnUse" x="-200" y="-200" width="1424" height="1424"'
grid=''.join(f'<line x1="{i}" y1="0" x2="{i}" y2="1024"/><line x1="0" y1="{i}" x2="1024" y2="{i}"/>' for i in range(0,1025,128))
html=f'''<!doctype html><html><body style="margin:0;background:#000">
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
  <radialGradient id="bg" cx="45%" cy="60%" r="75%"><stop offset="0" stop-color="#1c0d2e"/><stop offset=".6" stop-color="#0b0614"/><stop offset="1" stop-color="#040208"/></radialGradient>
  <radialGradient id="poolM"><stop offset="0" stop-color="#ff1f8f" stop-opacity=".5"/><stop offset="1" stop-color="#ff1f8f" stop-opacity="0"/></radialGradient>
  <radialGradient id="poolC"><stop offset="0" stop-color="#26f2ff" stop-opacity=".35"/><stop offset="1" stop-color="#26f2ff" stop-opacity="0"/></radialGradient>
  <filter id="glowL" {F}><feGaussianBlur stdDeviation="28"/></filter>
  <filter id="glowM" {F}><feGaussianBlur stdDeviation="11"/></filter>
  <pattern id="scan" width="8" height="8" patternUnits="userSpaceOnUse"><rect width="8" height="2" fill="#000" opacity=".12"/></pattern>
</defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
<ellipse cx="320" cy="740" rx="520" ry="400" fill="url(#poolM)"/>
<ellipse cx="840" cy="200" rx="380" ry="300" fill="url(#poolC)"/>
<g stroke="#fff" stroke-opacity=".045" stroke-width="2">{grid}</g>
{''.join(rain)}
<g filter="url(#glowM)">{bg_}{''.join(sparks)}</g>
{bl}{''.join(sparks)}
<path d="{body}" fill="none" stroke="#ff1f8f" stroke-width="66" stroke-linejoin="miter" filter="url(#glowL)" opacity=".85"/>
<path d="{body}" fill="#ff1f8f" fill-opacity=".2" stroke="#ff1f8f" stroke-width="38" stroke-linejoin="miter"/>
<path d="{body}" fill="none" stroke="#ffd6ec" stroke-width="11" stroke-linejoin="miter"/>
<path d="{crest}" fill="none" stroke="#c7ff1f" stroke-width="40" stroke-linejoin="miter" filter="url(#glowM)" opacity=".8"/>
<path d="{crest}" fill="none" stroke="#c7ff1f" stroke-width="24" stroke-linejoin="miter" stroke-linecap="square"/>
<path d="{crest}" fill="none" stroke="#f2ffc4" stroke-width="7" stroke-linejoin="miter"/>
<rect width="1024" height="1024" fill="url(#scan)"/>
</svg></body></html>'''
open('icon.html','w').write(html)
