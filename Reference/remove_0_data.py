import cv2
import numpy as np
import os
import glob

As = glob.glob(os.path.join(r"E:\JWExps\Hete\HeteData\xiongan_data\val\A", "*.png"))

for A in As:
    img = cv2.imread(A, cv2.IMREAD_UNCHANGED)
    zero_count = np.sum(img == 0)
    print("zero_count:",zero_count)
    print("img.size",img.size)
    if zero_count == img.size:
        os.remove(A)
        os.remove(A.replace("A", "B"))
        os.remove(A.replace("A", "label"))
Bs = glob.glob(os.path.join(r"E:\JWExps\Hete\HeteData\xiongan_data\val\B", "*.png"))
for B in Bs:
    img = cv2.imread(B, cv2.IMREAD_UNCHANGED)
    zero_count = np.sum(img == 0)
    if zero_count == img.size:
        os.remove(B)
        os.remove(B.replace("B", "A"))
        os.remove(B.replace("B", "label"))