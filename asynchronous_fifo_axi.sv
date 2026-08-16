
//------------------------------------------------------
// Asynchronous FIFO (DUT)
// - Write side: s_aclk domain
// - Read side : m_aclk domain
// - Gray-code pointers + 2-flop synchronizers for CDC safety
//------------------------------------------------------
module axis_async_fifo #(
  parameter DEPTH = 8,     // must be power of 2
  parameter DW    = 32
) (
  input  logic          s_aclk,
  input  logic          s_aresetn,
  input  logic [DW-1:0] s_tdata,
  input  logic          s_tvalid,
  output logic          s_tready,
  input  logic          s_tlast,

  input  logic          m_aclk,
  input  logic          m_aresetn,
  output logic [DW-1:0] m_tdata,
  output logic          m_tvalid,
  input  logic          m_tready,
  output logic          m_tlast
);

  localparam AW = $clog2(DEPTH);  // memory address width
  localparam PW = AW + 1;         // pointer width (extra MSB for full/empty)

  // Dual-port memory (write in s_aclk domain, async-read in m_aclk domain)
  logic [DW-1:0] mem_data [0:DEPTH-1];
  logic          mem_last [0:DEPTH-1];

  //---------------- Write domain (s_aclk) ----------------
  logic [PW-1:0] wr_ptr_bin, wr_ptr_bin_next;
  logic [PW-1:0] wr_ptr_gray, wr_ptr_gray_next;
  logic [PW-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
  logic          wr_en, full;

  assign wr_en    = s_tvalid && s_tready;
  assign s_tready = !full;

  assign wr_ptr_bin_next  = wr_ptr_bin + (wr_en ? {{PW-1{1'b0}}, 1'b1} : '0);
  assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

  always_ff @(posedge s_aclk or negedge s_aresetn) begin
    if (!s_aresetn) begin
      wr_ptr_bin  <= '0;
      wr_ptr_gray <= '0;
    end
    else begin
      wr_ptr_bin  <= wr_ptr_bin_next;
      wr_ptr_gray <= wr_ptr_gray_next;
    end
  end

  // 2-flop synchronizer: read pointer (gray) into write clock domain
  always_ff @(posedge s_aclk or negedge s_aresetn) begin
    if (!s_aresetn) begin
      rd_ptr_gray_sync1 <= '0;
      rd_ptr_gray_sync2 <= '0;
    end
    else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
  end

  assign full = (wr_ptr_gray_next ==
                 {~rd_ptr_gray_sync2[PW-1:PW-2], rd_ptr_gray_sync2[PW-3:0]});

  always_ff @(posedge s_aclk) begin
    if (wr_en) begin
      mem_data[wr_ptr_bin[AW-1:0]] <= s_tdata;
      mem_last[wr_ptr_bin[AW-1:0]] <= s_tlast;
    end
  end

  //---------------- Read domain (m_aclk) ----------------
  logic [PW-1:0] rd_ptr_bin, rd_ptr_bin_next;
  logic [PW-1:0] rd_ptr_gray;
  logic [PW-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
  logic          rd_en, empty;

  assign rd_en    = m_tvalid && m_tready;
  assign m_tvalid = !empty;
  assign m_tdata  = mem_data[rd_ptr_bin[AW-1:0]];
  assign m_tlast  = mem_last[rd_ptr_bin[AW-1:0]];

  assign rd_ptr_bin_next = rd_ptr_bin + (rd_en ? {{PW-1{1'b0}}, 1'b1} : '0);

  always_ff @(posedge m_aclk or negedge m_aresetn) begin
    if (!m_aresetn) begin
      rd_ptr_bin  <= '0;
      rd_ptr_gray <= '0;
    end
    else begin
      rd_ptr_bin  <= rd_ptr_bin_next;
      rd_ptr_gray <= (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;
    end
  end

  // 2-flop synchronizer: write pointer (gray) into read clock domain
  always_ff @(posedge m_aclk or negedge m_aresetn) begin
    if (!m_aresetn) begin
      wr_ptr_gray_sync1 <= '0;
      wr_ptr_gray_sync2 <= '0;
    end
    else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
  end

  assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

endmodule : axis_async_fifo
