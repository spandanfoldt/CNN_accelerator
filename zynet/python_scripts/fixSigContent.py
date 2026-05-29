inputFile = r"D:\VLSI\Projects\NN_accelerator\NN_accelerator.srcs\sources_1\new\sigContent.mif"
outputFile = r"D:\VLSI\Projects\NN_accelerator\NN_accelerator.sim\sim_1\behav\xsim\sigContent.mif"

with open(inputFile, 'r') as f:
    lines = [line.strip() for line in f if line.strip()]  # remove blank lines

print(f"Total lines in original file: {len(lines)}")

# Keep only first 1024 lines
lines = lines[:1024]

with open(outputFile, 'w') as f:
    for line in lines:
        f.write(line + '\n')

print(f"Written {len(lines)} lines to output file.")
