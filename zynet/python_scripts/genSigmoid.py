import math

outputFile = r"D:\VLSI\Projects\NN_accelerator\NN_accelerator.sim\sim_1\behav\xsim\sigContent.mif"

inWidth = 10
dataWidth = 16
fracBits = dataWidth - 1  # 15 fractional bits

numEntries = 2**inWidth  # exactly 1024

def sigmoid(x):
    return 1 / (1 + math.exp(-x))

with open(outputFile, 'w') as f:
    for i in range(numEntries):
        # Map index 0..1023 to input range -8.0 to +8.0
        x = -8.0 + (16.0 * i) / (numEntries - 1)
        sig = sigmoid(x)
        # Convert to 16-bit fixed point (Q1.15)
        val = int(sig * (2**fracBits))
        val = min(val, 2**dataWidth - 1)  # clamp
        f.write(format(val, '016b') + '\n')

print("Done! Written exactly", numEntries, "lines.")
