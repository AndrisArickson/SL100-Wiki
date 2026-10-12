"""Superseded by build_pages.py (kept so old notes still work).   python3 tools/talents_page.py"""
import runpy, sys
from pathlib import Path
sys.argv = [str(Path(__file__).with_name("build_pages.py"))]
runpy.run_path(sys.argv[0], run_name="__main__")
