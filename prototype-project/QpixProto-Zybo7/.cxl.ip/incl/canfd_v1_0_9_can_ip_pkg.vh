  localparam [5:0] ADDR_SRR             = 6'b000000; 
  localparam [5:0] ADDR_MSR             = 6'b000001; 
  localparam [5:0] ADDR_BRPR            = 6'b000010; 
  localparam [5:0] ADDR_BTR             = 6'b000011;
  localparam [5:0] ADDR_ECR             = 6'b000100; 
  localparam [5:0] ADDR_ESR             = 6'b000101; 
  localparam [5:0] ADDR_SR              = 6'b000110;
  localparam [5:0] ADDR_ISR             = 6'b000111; 
  localparam [5:0] ADDR_IER             = 6'b001000; 
  localparam [5:0] ADDR_ICR             = 6'b001001;
  localparam [5:0] ADDR_TSR             = 6'b001010;


  localparam ADDR_F_BRPR                = 6'b100010; 
  localparam ADDR_F_BTR                 = 6'b100011;
  localparam ADDR_TRR                   = 6'b100100; 
  localparam ADDR_IETRS                 = 6'b100101; 
  localparam ADDR_TCR                   = 6'b100110; 
  localparam ADDR_IECRS                 = 6'b100111; 

  localparam ADDR_RCS0                  = 6'b101100; 
  localparam ADDR_RCS1                  = 6'b101101; 
  localparam ADDR_RCS2                  = 6'b101110; 
  localparam ADDR_IERBF0                = 6'b110000; 
  localparam ADDR_IERBF1                = 6'b110001; 

  localparam ADDR_AFR                   = 6'b111000;
  localparam ADDR_FSR                   = 6'b111010; 
  localparam ADDR_WMR                   = 6'b111011; 

  localparam ADDR_TBP_REG               = 6'b010000; 
  localparam ADDR_TFM_REG               = 6'b010001; 
  localparam ADDR_TREQ_REG              = 6'b010011;

  localparam ADDR_RBP_REG               = 6'b010100; 
  localparam ADDR_RFM_REG               = 6'b010101; 
  localparam ADDR_RREQ_REG              = 6'b010111;  



  localparam [8:0] C0                   = 9'b000000000;
  localparam [8:0] C1                   = 9'b000000001;
  localparam [8:0] C2                   = 9'b000000010;
  localparam [8:0] C3                   = 9'b000000011;
  localparam [8:0] C4                   = 9'b000000100;
  localparam [8:0] C5                   = 9'b000000101;
  localparam [8:0] C6                   = 9'b000000110;
  localparam [8:0] C7                   = 9'b000000111; 
  localparam [8:0] C11                  = 9'b000001011;
  localparam [8:0] C12                  = 9'b000001100;
  localparam [8:0] C15                  = 9'b000001111;
  localparam [8:0] C17                  = 9'b000010001;
  localparam [8:0] C21                  = 9'b000010101;
  localparam [8:0] C30                  = 9'b000011110;
  localparam [8:0] C31                  = 9'b000011111;
  localparam [8:0] C32                  = 9'b000100000;
  localparam [8:0] C63                  = 9'b000111111;
  localparam [8:0] C95                  = 9'b001011111;
  localparam [8:0] C127                 = 9'b001111111;
  localparam [8:0] C159                 = 9'b010011111;
  localparam [8:0] C191                 = 9'b010111111;
  localparam [8:0] C223                 = 9'b011011111;
  localparam [8:0] C255                 = 9'b011111111;
  localparam [8:0] C287                 = 9'b100011111;
  localparam [8:0] C319                 = 9'b100111111;
  localparam [8:0] C351                 = 9'b101011111;
  localparam [8:0] C383                 = 9'b101111111;
  localparam [8:0] C415                 = 9'b110011111;
  localparam [8:0] C447                 = 9'b110111111;
  localparam [8:0] C479                 = 9'b111011111;
  localparam [8:0] C511                 = 9'b111111111;



  localparam [6:0] D0                   = 7'b0000000;
  localparam [6:0] D1                   = 7'b0000001;
  localparam [6:0] D2                   = 7'b0000010;
  localparam [6:0] D3                   = 7'b0000011;
  localparam [6:0] D4                   = 7'b0000100;
  localparam [6:0] D5                   = 7'b0000101;
  localparam [6:0] D6                   = 7'b0000110;
  localparam [6:0] D7                   = 7'b0000111; 
  localparam [6:0] D8                   = 7'b0001000;
  localparam [6:0] D12                  = 7'b0001100; 
  localparam [6:0] D16                  = 7'b0010000;
  localparam [6:0] D20                  = 7'b0010100;
  localparam [6:0] D24                  = 7'b0011000;
  localparam [6:0] D32                  = 7'b0100000;
  localparam [6:0] D48                  = 7'b0110000;
  localparam [6:0] D64                  = 7'b1000000;
                                     



