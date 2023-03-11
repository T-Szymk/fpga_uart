# Entity: baud_generator 

- **File**: baud_generator.v
## Diagram

![Diagram](baud_generator.svg "Diagram")
## Generics

| Generic name    | Type     | Value    | Description         |
| --------------- | -------- | -------- | ------------------- |
| TOP_CLK_FREQ_HZ | unsigned | 50000000 | Top clock frequency |
## Ports

| Port name  | Direction | Type         | Description                   |
| ---------- | --------- | ------------ | ----------------------------- |
| clk_i      | input     | wire         | Clock                         |
| rst_i      | input     | wire         | Active-high synchronous reset |
| baud_sel_i | input     | wire [2-1:0] | Baud-rate select signal       |
| baud_en_o  | output    | wire         | Baud clock enable signal      |
## Signals

| Name               | Type                         | Description                                      |
| ------------------ | ---------------------------- | ------------------------------------------------ |
| baud_en_r          | reg                          | Baud clock enable signal                         |
| select_update_s    | reg                          | Indicates baud rate select has been updated      |
| baud_sel_r         | reg [                 2-1:0] | Baud rate select register to detect value update |
| sample_count_max_s | reg [SAMPLE_COUNT_WIDTH-1:0] | Register holding maximum value of sample counter |
| sample_count_r     | reg [SAMPLE_COUNT_WIDTH-1:0] | Sample counter register                          |
## Constants

| Name                           | Type    | Value                                | Description |
| ------------------------------ | ------- | ------------------------------------ | ----------- |
| MIN_SAMPLE_FREQ_9600_BAUD_HZ   | integer | 153600                               |             |
| MIN_SAMPLE_FREQ_19200_BAUD_HZ  | integer | 307200                               |             |
| MIN_SAMPLE_FREQ_115200_BAUD_HZ | integer | 1843200                              |             |
| MIN_SAMPLE_FREQ_256000_BAUD_HZ | integer | 4086000                              |             |
| SAMPLE_COUNT_9600_BAUD         | integer | undefined                            |             |
| SAMPLE_COUNT_19200_BAUD        | integer | undefined                            |             |
| SAMPLE_COUNT_115200_BAUD       | integer | undefined                            |             |
| SAMPLE_COUNT_256000_BAUD       | integer | undefined                            |             |
| SAMPLE_COUNT_WIDTH             | integer | $clog2(SAMPLE_COUNT_256000_BAUD + 1) |             |
## Processes
- sync_sample_count: ( @(posedge clk_i) )
  - **Type:** always
- sync_baud_sel: ( @(posedge clk_i) )
  - **Type:** always
- comb_baud_count_select: ( @( baud_sel_i ) )
  - **Type:** always
- sync_baud_update: ( @( baud_sel_r, baud_sel_i ) )
  - **Type:** always
