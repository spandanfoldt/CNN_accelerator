import random

NUM_WEIGHTS = 784
BIT_WIDTH = 16

with open("w_1_15.mif", "w") as f:


    for addr in range(NUM_WEIGHTS):

        # random signed integer
        value = random.randint(-(2**(BIT_WIDTH-1)),
                                 2**(BIT_WIDTH-1)-1)

        # convert to 2's complement binary
        binary = format(value & ((1 << BIT_WIDTH)-1),
                        f'0{BIT_WIDTH}b')

        f.write(binary + "\n")
