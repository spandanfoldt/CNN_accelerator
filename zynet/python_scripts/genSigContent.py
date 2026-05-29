import math

inWidth = 10
dataWidth = 16
dataFracWidth = 15  # 1 sign bit + 15 fractional bits for output

outputFile = r"D:\VLSI\Projects\NN_accelerator\NN_accelerator.sim\sim_1\behav\xsim\sigContent.mif"

def sigmoid(x):
    return 1 / (1 + math.exp(-x))

def DtoB(num, dataWidth, fracBits):
    if num >= 0:
        num = int(num * (2**fracBits))
        d = num
    else:
        num = int(-num * (2**fracBits))
        if num == 0:
            d = 0
        else:
            d = 2**dataWidth - num
    return d

numEntries = 2**inWidth  # 1024

# Input range: covers signed 10-bit values mapped to a float range
# Typically -8 to +8 for sigmoid to be meaningful
inputMin = -8.0
inputMax = 8.0

with open(outputFile, 'w') as f:
    for i in range(numEntries):
        # Map index to input value
        x = inputMin + (inputMax - inputMin) * i / (numEntries - 1)
        sig = sigmoid(x)
        # Convert to fixed point binary
        val = DtoB(sig, dataWidth, dataFracWidth)
        binary = format(val, '016b')
        f.write(binary + '\n')

print("sigContent.mif generated successfully with", numEntries, "entries.")
