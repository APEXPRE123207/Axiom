# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['w:/CODE/My-Apps/Axiom/axiom_desktop/gui.py'],
    pathex=['w:/CODE/My-Apps/Axiom/axiom_desktop'],
    binaries=[],
    datas=[('w:/CODE/My-Apps/Axiom/logo.png', '.')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='AxiomDesktop',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['w:/CODE/My-Apps/Axiom/logo.ico'],
)
