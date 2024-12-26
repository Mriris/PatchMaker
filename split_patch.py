import cv2
import numpy as np
import os

def process_and_save_patches(img, patch_size, stride, output_dir, filename):
    # 切片、保存图像，并统计每个patch中0的数量
    h, w = img.shape[:2]
    for y in range(0, h-patch_size+1, stride):
        for x in range(0, w-patch_size+1, stride):
            patch = img[y:y+patch_size, x:x+patch_size]
            if patch.shape[0] == patch_size and patch.shape[1] == patch_size:
                # zero_count = np.sum(patch == [0,0,0])  # 计算0的数量
                patch_filename = f"{filename}_{y}_{x}.png"
                cv2.imwrite(os.path.join(output_dir, patch_filename), patch)
                # print(f"Patch {patch_filename} has {zero_count} zeros.")

# 设定文件夹路径
input_dirs = ["A", "B", "label"]
base_dir = "E:/JWExps/Hete/HeteData/mask_data/val"  # 替换为你的数据集路径
output_base = "./xiongan_data/val"  # 替换为输出目录路径
patch_size = 512
stride = 256  # 添加步长参数

# 创建输出文件夹
for dir_name in input_dirs:
    os.makedirs(os.path.join(output_base, dir_name), exist_ok=True)

# 遍历label文件夹中的所有文件
for label_filename in os.listdir(os.path.join(base_dir, "label")):
    # 构建相应的A和B文件的路径
    a_path = os.path.join(base_dir, "A", label_filename.replace(".png", ".tif"))
    b_path = os.path.join(base_dir, "B", label_filename.replace(".png", ".tif"))
    label_path = os.path.join(base_dir, "label", label_filename)

    # 读取图像文件
    if os.path.exists(a_path) and os.path.exists(b_path):
        img_a = cv2.imread(a_path, cv2.IMREAD_UNCHANGED)
        img_b = cv2.imread(b_path, cv2.IMREAD_UNCHANGED)
        img_label = cv2.imread(label_path, cv2.IMREAD_UNCHANGED)

        # 对三个文件夹下的图像进行切片并根据条件保存
        base_filename, _ = os.path.splitext(label_filename)
        process_and_save_patches(img_a, patch_size, stride, os.path.join(output_base, "A"), base_filename)
        process_and_save_patches(img_b, patch_size, stride, os.path.join(output_base, "B"), base_filename)
        process_and_save_patches(img_label, patch_size, stride, os.path.join(output_base, "label"), base_filename)
