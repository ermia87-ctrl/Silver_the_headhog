#!/usr/bin/env python3
"""Connect Persian title credits, Try Again and Level Select graphics to Sonic 1."""
from pathlib import Path
import json, subprocess, sys
from PIL import Image, ImageDraw, ImageFont
import arabic_reshaper
from bidi.algorithm import get_display

ROOT=Path(__file__).resolve().parents[1]
SRC=Path(sys.argv[1]); TOOL=Path(sys.argv[2]); OUT=ROOT/"credits-level-select-patch"
CAT=ROOT/"translations/fa-IR.json"
FONT="/usr/share/fonts/truetype/noto/NotoNaskhArabic-Regular.ttf"

def run(args): subprocess.run([str(x) for x in args],check=True)
def tile_bytes(im):
    out=bytearray(); p=im.load()
    for y in range(8):
        planes=[0,0,0,0]
        for x in range(8):
            for b in range(4):
                if (1 if p[x,y] else 0)&(1<<b): planes[b]|=1<<(7-x)
        out.extend(planes)
    return bytes(out)
def encode_image(im):
    out=bytearray()
    for y in range(0,im.height,8):
        for x in range(0,im.width,8): out.extend(tile_bytes(im.crop((x,y,x+8,y+8))))
    return bytes(out)
def fitted(text,w,h,size):
    visual=get_display(arabic_reshaper.reshape(text)); font=ImageFont.truetype(FONT,size)
    probe=Image.new("L",(1,1)); box=ImageDraw.Draw(probe).textbbox((0,0),visual,font=font)
    glyph=Image.new("L",(max(1,box[2]-box[0]),max(1,box[3]-box[1])))
    ImageDraw.Draw(glyph).text((-box[0],-box[1]),visual,font=font,fill=255)
    scale=min(w/glyph.width,h/glyph.height,1)
    if scale<1: glyph=glyph.resize((max(1,int(glyph.width*scale)),max(1,int(glyph.height*scale))),Image.Resampling.LANCZOS)
    im=Image.new("L",(w,h)); im.paste(glyph,((w-glyph.width)//2,(h-glyph.height)//2))
    return im.point(lambda v:255 if v>=80 else 0),visual
def compress(raw,name):
    src=OUT/(name+".4bpp"); dst=OUT/(name+".nem"); check=OUT/(name+".check")
    src.write_bytes(raw); run([TOOL,"-c",src,dst]); run([TOOL,"-d",dst,check])
    if check.read_bytes()!=raw: raise SystemExit("Nemesis round-trip failed: "+name)
    check.unlink(); return dst
def glyph(ch,font):
    probe=Image.new("L",(1,1)); box=ImageDraw.Draw(probe).textbbox((0,0),ch,font=font)
    g=Image.new("L",(max(1,box[2]-box[0]),max(1,box[3]-box[1])))
    ImageDraw.Draw(g).text((-box[0],-box[1]),ch,font=font,fill=255)
    sc=min(8/g.width,8/g.height,1)
    if sc<1:g=g.resize((max(1,int(g.width*sc)),max(1,int(g.height*sc))),Image.Resampling.LANCZOS)
    im=Image.new("L",(8,8)); im.paste(g,((8-g.width)//2,(8-g.height)//2))
    return im.point(lambda v:255 if v>=80 else 0)
def make_level(catalog):
    lines=[]
    for zone in ["تپه سبز","هزارتو","غار مرمر","نور ستاره","باغ بهاری","مغز آهنی"]:
        for stage in (1,2,3): lines.append(f"{zone} - مرحله {stage}")
    lines += ["منطقه نهایی","مرحله ویژه","انتخاب صدا"]
    title=catalog["game"]["level_select"]
    visual=[get_display(arabic_reshaper.reshape(x)) for x in [title]+lines]
    forms=sorted({c for line in visual for c in line if c not in " 0123456789"})
    if 16+len(forms)>127: raise SystemExit("Too many Persian glyph forms for the Level Select font")
    f=ImageFont.truetype(FONT,10)
    latin=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",8)
    tiles=[]
    for c in "0123456789ABCDEF":
        im=Image.new("L",(8,8)); d=ImageDraw.Draw(im); b=d.textbbox((0,0),c,font=latin)
        d.text(((8-(b[2]-b[0]))//2-b[0],(8-(b[3]-b[1]))//2-b[1]),c,font=latin,fill=255)
        tiles.append(im.point(lambda v:255 if v>=80 else 0))
    ids={c:16+i for i,c in enumerate(forms)}
    tiles += [glyph(c,f) for c in forms]
    def line_bytes(s):
        cells=[0xFF if c==" " else ord(c)-48 if c.isdigit() else ids[c] for c in s]
        if len(cells)>24: raise SystemExit("Level Select row exceeds 24 tiles: "+s)
        return [0xFF]*(24-len(cells))+cells
    return b"".join(tile_bytes(t) for t in tiles),line_bytes(visual[0]),[line_bytes(v) for v in visual[1:]],len(forms),len(tiles)

def dc(values): return "\t\tdc.b "+",".join("$%02X"%v for v in values)
def replace_between(s,start,end,new):
    a=s.find(start); b=s.find(end,a+len(start))
    if a<0 or b<0: raise SystemExit("Missing source block: "+start)
    b+=len(end); return s[:a]+new+s[b:]

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    if not Path(FONT).exists(): raise SystemExit("Noto Arabic font missing")
    cat=json.loads(CAT.read_text(encoding="utf-8")); game=cat["game"]
    stp,stpv=fitted(game["sonic_team_presents"],128,16,14)
    tr, trv=fitted(game["try_again"],96,16,14)
    stp.save(OUT/"sonic-team-presents.png"); tr.save(OUT/"try-again.png")
    a=compress(encode_image(stp),"persian-sonic-team-presents")
    b=compress(encode_image(tr),"persian-try-again")
    level,title_bytes,rows,forms,tilecount=make_level(cat)
    c=compress(level,"persian-level-select")

    maps=SRC/"_maps/Credits.asm"
    s=maps.read_text(encoding="utf-8")
    replacement=""".tryagain:\tspriteHeader\t; Persian: دوباره تلاش کن
\tspritePiece\t-$30, $30, 4, 2, 0, 0, 0, 0, 0
\tspritePiece\t-$10, $30, 4, 2, 8, 0, 0, 0, 0
\tspritePiece\t$10, $30, 4, 2, $10, 0, 0, 0, 0
.tryagain_End


.sonicteampresents:\tspriteHeader\t; Persian: تیم سونیک تقدیم می‌کند
\tspritePiece\t-$40, -$18, 4, 2, 0, 0, 0, 0, 0
\tspritePiece\t-$20, -$18, 4, 2, 8, 0, 0, 0, 0
\tspritePiece\t0, -$18, 4, 2, $10, 0, 0, 0, 0
\tspritePiece\t$20, -$18, 4, 2, $18, 0, 0, 0, 0
.sonicteampresents_End"""
    s=replace_between(s,".tryagain:",".sonicteampresents_End",replacement)
    maps.write_text(s,encoding="utf-8")

    obj=SRC/"_incObj/8A Credits and Sonic Team Presents.asm"
    s=obj.read_text(encoding="utf-8")
    old="""\t\tcmpi.b\t#id_Title,(v_gamemode).w\t\t; is the mode #4 (title screen)?
\t\tbne.s\tCred_Display\t\t\t\t; if not, branch
\t\tmove.w\t#ArtTile_Sonic_Team_Font,obGfx(a0)\t; alternate art tile offset for title screen
\t\tmove.b\t#$A,obFrame(a0)\t\t\t\t; display \"SONIC TEAM PRESENTS\" frame"""
    new="""\t\tcmpi.b\t#id_Title,(v_gamemode).w\t\t; title splash?
\t\tbne.s\tCred_CheckTryAgain
\t\tmove.w\t#ArtTile_Sonic_Team_Font,obGfx(a0)
\t\tmove.b\t#$A,obFrame(a0)
\t\tbra.s\tCred_Display
Cred_CheckTryAgain:
\t\tcmpi.w\t#9,(v_creditsnum).w\t\t\t; Try Again page?
\t\tbne.s\tCred_Display
\t\tmove.w\t#ArtTile_Sonic_Team_Font,obGfx(a0)"""
    if old not in s: raise SystemExit("CreditsText object branch not found")
    obj.write_text(s.replace(old,new,1),encoding="utf-8")

    sonic=SRC/"sonic.asm"; s=sonic.read_text(encoding="utf-8")
    old="""\t\tlocVRAM\tArtTile_Sonic_Team_Font*tile_size\t; set target VRAM location for \"SONIC TEAM PRESENTS\" font
\t\tlea\t(Nem_CreditText).l,a0\t\t\t; load STP font (same as the credits font)
\t\tbsr.w\tNemDec\t\t\t\t\t; decompress Nemesis-compressed patterns directly to VRAM"""
    new="""\t\tlocVRAM\tArtTile_Sonic_Team_Font*tile_size\t; Persian title splash font
\t\tlea\t(Nem_PersianSTP).l,a0
\t\tbsr.w\tNemDec"""
    if old not in s: raise SystemExit("Title font loader not found")
    s=s.replace(old,new,1)
    old="""\t\tmoveq\t#plcid_TryAgain,d0\t\t\t; load \"TRY AGAIN\" and \"END\" patterns
\t\tbsr.w\tQuickPLC\t\t\t\t; execute PLCs immediately (no queue)"""
    new=old+"""
\t\tlocVRAM\tArtTile_Sonic_Team_Font*tile_size\t; Persian Try Again font
\t\tlea\t(Nem_PersianTryAgain).l,a0
\t\tbsr.w\tNemDec"""
    if old not in s: raise SystemExit("Try Again screen loader not found")
    s=s.replace(old,new,1)
    old="""\t\tlocVRAM\tArtTile_Level_Select_Font*tile_size,4(a6) ; set target VRAM location for level select font
\t\tlea\t(Art_Text).l,a5\t\t\t\t; load uncompressed level select font
\t\tmove.w\t#(Art_Text_end-Art_Text)/2-1,d1\t\t; set loop count for level select
Tit_LoadText:
\t\tmove.w\t(a5)+,(a6)\t\t\t\t; write one row of the level select font to VRAM
\t\tdbf\td1,Tit_LoadText\t\t\t\t; loop until it's fully loaded"""
    new="""\t\tlocVRAM\tArtTile_Level_Select_Font*tile_size ; Persian level-select font
\t\tlea\t(Nem_PersianLevelSelect).l,a0
\t\tbsr.w\tNemDec"""
    if old not in s: raise SystemExit("Level Select font loader not found")
    s=s.replace(old,new,1)
    old="""LevSelTextLoad:
\t\t; Write main text in white
\t\tlea\t(LevelMenuText).l,a1"""
    new="""LevSelTextLoad:
\t\t; Persian heading in the unused row above the menu
\t\tlea\t(vdp_data_port).l,a6
\t\tlocVRAM\tvram_bg+(3<<7)+(levsel_start_col<<1),d4
\t\tmove.w\t#levsel_white,d3
\t\tmove.l\td4,4(a6)
\t\tlea\t(LevelMenuTitle).l,a1
\t\tbsr.w\tLevSel_ChgLine
\t\t; Write main text in white
\t\tlea\t(LevelMenuText).l,a1"""
    if old not in s: raise SystemExit("Level Select draw routine not found")
    s=s.replace(old,new,1)
    start=s.find("LevelMenuText:"); end=s.find("\n\tif MOMPASS=1",start)
    if start<0 or end<0: raise SystemExit("LevelMenuText block not found")
    block="LevelMenuTitle:\n"+dc(title_bytes)+"\n\nLevelMenuText:\n"+"\n".join(dc(r) for r in rows)+"\n"
    s=s[:start]+block+s[end:]

    # Compensate for compressed title/HUD assets that became shorter.
    # This preserves the original sound-driver and 512 KiB ROM boundary.
    asset_delta=0
    for asset_name in ["artnem/Title Screen Foreground.nem","artnem/HUD.nem"]:
        original_size=int(subprocess.check_output(["git","-C",str(SRC),"cat-file","-s","HEAD:"+asset_name],text=True).strip())
        current_size=(SRC/asset_name).stat().st_size
        align2=lambda n:(n+1)&~1
        asset_delta += align2(original_size)-align2(current_size)

    marker="""\tif PaddingOptimization=0
\t\tif Revision=0
\t\t\tdcb.b\t$62A,$FF"""
    assets=f"""Nem_PersianAssets_Start:
Nem_PersianSTP:\tbinclude\t"artnem/Persian - Sonic Team Presents.nem"
\t\teven
Nem_PersianTryAgain:\tbinclude\t"artnem/Persian - Try Again.nem"
\t\teven
Nem_PersianLevelSelect:\tbinclude\t"artnem/Persian - Level Select.nem"
\t\teven
Nem_PersianAssets_End:

\tif PaddingOptimization=0
\t\tif Revision=0
\t\t\tdcb.b\t$62A+{asset_delta}-(Nem_PersianAssets_End-Nem_PersianAssets_Start),$FF"""
    if marker not in s: raise SystemExit("REV00 sound-driver padding marker not found")
    s=s.replace(marker,assets,1)
    sonic.write_text(s,encoding="utf-8")

    art=SRC/"artnem"; art.mkdir(exist_ok=True)
    for src,name in [(a,"Persian - Sonic Team Presents.nem"),(b,"Persian - Try Again.nem"),(c,"Persian - Level Select.nem")]:
        (art/name).write_bytes(src.read_bytes())
    total=sum((art/n).stat().st_size for n in ["Persian - Sonic Team Presents.nem","Persian - Try Again.nem","Persian - Level Select.nem"])
    if total>0x62A+asset_delta: raise SystemExit(f"Persian art is {total} bytes; exceeds available padding {0x62A+asset_delta}")
    report={"patch":"credits_try_again_level_select","team_presents":game["sonic_team_presents"],"try_again":game["try_again"],"level_select_heading":game["level_select"],"level_rows":21,"unique_glyph_forms":forms,"level_font_tiles":tilecount,"compressed_asset_bytes":total,"padding_budget":0x62A+asset_delta,"existing_asset_size_compensation":asset_delta,"credits_names_preserved":True,"nemesis_roundtrip":"exact"}
    (OUT/"integration-report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,ensure_ascii=False,indent=2))

if __name__=="__main__": main()
