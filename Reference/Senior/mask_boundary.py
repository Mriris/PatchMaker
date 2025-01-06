import cv2
import numpy as np
import os
from skimage import io


# 设定文件夹路径
input_dirs = ["A", "B", "label"]
base_dir = "../../"  # 替换为你的数据集路径"
output_base = "./mask_data"  # 替换为输出目录路径
patch_size = 512
zero_threshold = 100  # 切片中0的最大数量

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
        img_a = io.imread(a_path)
        img_b = io.imread(b_path)
        img_label = io.imread(label_path)
        if img_a.shape!=img_b.shape:
            print(img_a.shape, img_b.shape)
            print("shape not match")
            # continue
        if img_a.shape[0] > img_b.shape[0] or img_a.shape[1] > img_b.shape[1]:
            img_a = img_a[:img_b.shape[0], :img_b.shape[1], :]
            img_label = img_label[:img_b.shape[0], :img_b.shape[1]]
        if img_a.shape[0] < img_b.shape[0] or img_a.shape[1] < img_b.shape[1]:
            img_b = img_b[:img_a.shape[0], :img_a.shape[1], :]
            img_label = img_label[:img_a.shape[0], :img_a.shape[1]]
        
        mask_zero1 = np.zeros_like(img_a)
        mask_zero2 = np.zeros_like(img_b)
        img_b_ = cv2.blur(img_b, (9, 9))
        mask_a = np.where(img_a ==[255,255,255], 0, 1).astype(np.uint8)[:,:,0]
        mask_b = np.where(img_b_ ==[255,255,255], 0, 1).astype(np.uint8)[:,:,0]
        e,_ = cv2.findContours(mask_a, cv2.RETR_EXTERNAL, cv2.RETR_TREE)
        mask_a = cv2.drawContours(mask_zero1, e, -1, (1,1,1), -1)
        e,_ = cv2.findContours(mask_b, cv2.RETR_EXTERNAL, cv2.RETR_TREE)
        mask_b = cv2.drawContours(mask_zero2, e, -1, (1,1,1), -1)
        mask = mask_a * mask_b
        io.imsave(os.path.join(output_base, "mask", label_filename), mask*255)
        new_label = img_label * mask[:,:,0]
        new_a = img_a * mask
        new_b = img_b * mask
        io.imsave(os.path.join(output_base, "A", label_filename.replace(".png", ".tif")), new_a)
        io.imsave(os.path.join(output_base, "B", label_filename.replace(".png", ".tif")), new_b)
        io.imsave(os.path.join(output_base, "label", label_filename), new_label)
        

