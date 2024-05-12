import numpy as np 

n = 1024
i_vals = np.arange(n, dtype=np.float64)
c = np.cos(i_vals*np.pi/n)
with open('cos_table.txt', 'w') as f:
    for i, e in enumerate(c):
        f.write(f'    if (i == {i})\n')
        f.write(f'        return {e};\n')