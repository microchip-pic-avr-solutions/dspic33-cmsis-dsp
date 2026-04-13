import os
import xml.etree.ElementTree as ET

# -------------------------------
# CONFIGURABLE PATHS
# -------------------------------
PROJECT_ROOT = r"Testing/lib_cmsis_dsp_mchp/lib_cmsis_dsp_mchp_project.X"
CONFIG_XML = os.path.join(PROJECT_ROOT, "nbproject", "configurations.xml")

SOURCE_DIR = "Source"
INCLUDE_DIR = "Include"
PRIVATE_INCLUDE_DIR = "PrivateInclude"

SRC_EXT = [".c", ".s"]
INC_EXT = [".h"]
PRIVATE_EXT = [".h", ".inc"]
# -------------------------------

def scan_tree(base_dir, valid_ext):
    """Recursively scan base_dir, return {rel_dir: [file1, file2, ...]}"""
    out = {}
    for root, _, files in os.walk(base_dir):
        rel_dir = os.path.relpath(root, PROJECT_ROOT).replace("\\", "/")
        file_list = [os.path.join(rel_dir, f).replace("\\", "/")
                     for f in files if any(f.lower().endswith(e) for e in valid_ext)]
        if file_list:
            out[rel_dir] = file_list
    return out

def find_or_create_folder(parent, name, displayName):
    for lf in parent.findall("logicalFolder"):
        if lf.get("name") == name:
            return lf
    new_lf = ET.SubElement(parent, "logicalFolder")
    new_lf.set("name", name)
    new_lf.set("displayName", displayName)
    new_lf.set("projectFiles", "true")
    return new_lf

def find_or_create_subfolder(parent, rel_path):
    """Create nested logicalFolders for rel_path (e.g. Source/sub1/sub2)"""
    parts = rel_path.split("/")
    current = parent
    for part in parts:
        lf = None
        for child in current.findall("logicalFolder"):
            if child.get("name") == part:
                lf = child
                break
        if lf is None:
            lf = ET.SubElement(current, "logicalFolder")
            lf.set("name", part)
            lf.set("displayName", part)
            lf.set("projectFiles", "true")
        current = lf
    return current


def add_items(folder, items):
    for path in items:
        ip = ET.SubElement(folder, "itemPath")
        ip.text = path

def update_config_xml():
    tree = ET.parse(CONFIG_XML)
    root = tree.getroot()
    root_folder = root.find("./logicalFolder[@name='root']")
    if root_folder is None:
        raise Exception("Root <logicalFolder name='root'> not found in configurations.xml")

    # Create/find top-level folders
    source_folder = find_or_create_folder(root_folder, "SourceFiles", "Source Files")
    include_folder = find_or_create_folder(root_folder, "HeaderFiles", "Header Files")

    # Scan and add files/folders recursively
    for base_dir, valid_ext, top_folder in [
        (SOURCE_DIR, SRC_EXT, source_folder),
        (INCLUDE_DIR, INC_EXT, include_folder),
        (PRIVATE_INCLUDE_DIR, PRIVATE_EXT, include_folder)
    ]:
        tree_dict = scan_tree(base_dir, valid_ext)
        for rel_dir, files in tree_dict.items():
            if rel_dir == base_dir:
                folder = top_folder
            else:
                folder = find_or_create_subfolder(top_folder, rel_dir[9:])
            add_items(folder, files)

    tree.write(CONFIG_XML, encoding="UTF-8", xml_declaration=True)
    print("Library Project configurations.xml Updated with all source (.c, .s) and header files (.h, .inc)")

if __name__ == "__main__":
    update_config_xml()
