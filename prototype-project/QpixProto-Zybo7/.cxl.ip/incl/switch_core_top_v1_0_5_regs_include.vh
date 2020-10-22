//
localparam CTL_FRAME_VLAN_TAG                 = 16'h8808;
localparam VLAN_FRAME_ETHER_TYPE              = 16'h8100;
localparam FRAME_ETHER_TYPE                   = 16'h0600;
localparam PTP_FRAME_VLAN_TAG                 = 16'h88F7;
localparam FRER_ETHER_TYPE                    = 16'hF1C1;

localparam C_NUM_READ_MUXES                   = 1;
localparam C_SWITCH_CFG_BASE_OFFSET           = 32'h00000000;

// READ_MUX=0
//Configuration Registers Offset 0-511
localparam C_SWITCH_STATUS_ADDR                    = C_SWITCH_CFG_BASE_OFFSET+32'h00000000;  //
localparam C_SWITCH_CONTROL_ADDR                   = C_SWITCH_CFG_BASE_OFFSET+32'h00000004;  //
localparam C_SWITCH_PRIORITY_MAP_ADDR              = C_SWITCH_CFG_BASE_OFFSET+32'h00000008;  //
localparam C_SWITCH_MAC_LSB32_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h0000000C;  //
localparam C_SWITCH_MAC_MSB16_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00000010;  //
localparam C_EP_PRI7_FIFO_THRESHOLD_ADDR           = C_SWITCH_CFG_BASE_OFFSET+32'h00000020;  //
localparam C_EP_PRI6_FIFO_THRESHOLD_ADDR           = C_SWITCH_CFG_BASE_OFFSET+32'h00000024;  //
localparam C_EP_PRI5_FIFO_THRESHOLD_ADDR           = C_SWITCH_CFG_BASE_OFFSET+32'h00000028;  //
localparam C_MAC_PRI7_FIFO_THRESHOLD_ADDR          = C_SWITCH_CFG_BASE_OFFSET+32'h00000030;  //
localparam C_MAC_PRI6_FIFO_THRESHOLD_ADDR          = C_SWITCH_CFG_BASE_OFFSET+32'h00000034;  //
localparam C_MAC_PRI5_FIFO_THRESHOLD_ADDR          = C_SWITCH_CFG_BASE_OFFSET+32'h00000038;  //
localparam C_PORT0_DEFAULT_VLAN_ADDR               = C_SWITCH_CFG_BASE_OFFSET+32'h00000040;  //
localparam C_PORT1_DEFAULT_VLAN_ADDR               = C_SWITCH_CFG_BASE_OFFSET+32'h00000044;  //
localparam C_HW_ADDR_LEARNING_CTRL_ADDR            = C_SWITCH_CFG_BASE_OFFSET+32'h00000048;  // 10b port map, DMAC[47:32]
localparam C_PORT_STATE_CFG_ADDR                   = C_SWITCH_CFG_BASE_OFFSET+32'h0000004C;  //

localparam C_MGMT_VLAN_TYPE_ADDR                   = C_SWITCH_CFG_BASE_OFFSET+32'h00000050;  //
localparam C_CPU_VLAN_TYPE_1_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00000054;  //
localparam C_PRI7_MAX_FRAME_SIZE                   = C_SWITCH_CFG_BASE_OFFSET+32'h00000060;  //
localparam C_PRI6_MAX_FRAME_SIZE                   = C_SWITCH_CFG_BASE_OFFSET+32'h00000064;  //
localparam C_PRI5_MAX_FRAME_SIZE                   = C_SWITCH_CFG_BASE_OFFSET+32'h00000068;  //
localparam C_PRI4_MAX_FRAME_SIZE                   = C_SWITCH_CFG_BASE_OFFSET+32'h0000006C;  //
localparam C_PRI3_MAX_FRAME_SIZE                   = C_SWITCH_CFG_BASE_OFFSET+32'h00000070;  //
localparam C_PRI2_MAX_FRAME_SIZE                   = C_SWITCH_CFG_BASE_OFFSET+32'h00000074;  //
localparam C_PRI1_MAX_FRAME_SIZE                   = C_SWITCH_CFG_BASE_OFFSET+32'h00000078;  //
localparam C_PRI0_MAX_FRAME_SIZE                   = C_SWITCH_CFG_BASE_OFFSET+32'h0000007C;  //
// Register Based Fast Statistics Registers at offset of 256-512
// Memory Based Statistics Registers at offset of 1024-2047
localparam C_SWITCH_STATISTICS_LSB                 = C_SWITCH_CFG_BASE_OFFSET+32'h00000400;  // Lower
localparam C_SWITCH_STATISTICS_MSB                 = C_SWITCH_CFG_BASE_OFFSET+32'h000007FC;  // Upper

localparam C_CAM_MISS_PACKETS_0_ADDR               = C_SWITCH_CFG_BASE_OFFSET+32'h00000800;  // Upper
localparam C_CAM_MISS_PACKETS_1_ADDR               = C_SWITCH_CFG_BASE_OFFSET+32'h00000804;  // Upper
localparam C_MULTICAST_PACKETS_0_ADDR              = C_SWITCH_CFG_BASE_OFFSET+32'h00000808;  // Upper
localparam C_MULTICAST_PACKETS_1_ADDR              = C_SWITCH_CFG_BASE_OFFSET+32'h0000080C;  // Upper

localparam C_DMAC_PORT_LUT_0_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001000;  // Control [0] valid, [1] op
localparam C_DMAC_PORT_LUT_1_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001004;  // Status init_done, size, cam_size, eccerr
localparam C_DMAC_PORT_LUT_2_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001008;  // DMAC[31:0]
localparam C_DMAC_PORT_LUT_3_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h0000100C;  // 10b port map, DMAC[47:32]
localparam C_DMAC_PORT_LUT_4_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001010;  // 10b port map, DMAC[47:32]
localparam C_DMAC_PORT_LUT_5_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001014;  // 10b port map, DMAC[47:32]
localparam C_DMAC_PORT_LUT_6_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001018;  // 10b port map, DMAC[47:32]

localparam C_PORT_VLAN_CONFIG_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00001100;  //
localparam C_PORT_VLAN_DATA_ADDR                   = C_SWITCH_CFG_BASE_OFFSET+32'h00001104;  //

localparam C_PSFP_CONTROL_ADDR                     = C_SWITCH_CFG_BASE_OFFSET+32'h00001200;  // Control [0] valid, [1] op
localparam C_PSFP_FILTER_CONFIG_ADDR               = C_SWITCH_CFG_BASE_OFFSET+32'h00001204;  // Status init_done, size, cam_size, eccerr
localparam C_PSFP_METER_LUT_0_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00001208;  // SMAC lower
localparam C_PSFP_METER_LUT_1_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h0000120C;  // SMAC Upper 
localparam C_PSFP_METER_LUT_2_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00001210;  // SMAC Upper 
localparam C_PSFP_METER_LUT_3_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00001214;  // SMAC Upper 

localparam C_FRER_CONTROL_ADDR                     = C_SWITCH_CFG_BASE_OFFSET+32'h00001300;  // Control [0] valid, [1] op
localparam C_FRER_FILTER_CONFIG_ADDR               = C_SWITCH_CFG_BASE_OFFSET+32'h00001304;  // Status init_done, size, cam_size, eccerr
localparam C_FRER_MEMBER_LUT_0_ADDR                = C_SWITCH_CFG_BASE_OFFSET+32'h00001308;  // SMAC lower
localparam C_FRER_MEMBER_LUT_1_ADDR                = C_SWITCH_CFG_BASE_OFFSET+32'h0000130C;  // SMAC Upper 
localparam C_FRER_MEMBER_LUT_2_ADDR                = C_SWITCH_CFG_BASE_OFFSET+32'h00001310;  // SMAC Upper 
localparam C_FRER_MEMBER_LUT_3_ADDR                = C_SWITCH_CFG_BASE_OFFSET+32'h00001314;  // SMAC Upper 

localparam C_SMAC_DROP_LUT_0_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001400;  // Control [0] valid, [1] op
localparam C_SMAC_DROP_LUT_1_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001404;  // Status init_done, size, cam_size, eccerr
localparam C_SMAC_DROP_LUT_2_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h00001408;  // SMAC lower
localparam C_SMAC_DROP_LUT_3_ADDR                  = C_SWITCH_CFG_BASE_OFFSET+32'h0000140C;  // SMAC Upper 

// LSB ADDR are required to be aligned at 8K boundary
localparam C_PSFP_STATS_1_LSB_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00002000;  // Lower
localparam C_PSFP_STATS_1_MSB_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00003FFC;  // Upper
localparam C_FRER_STATS_1_LSB_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00004000;  // Lower
localparam C_FRER_STATS_1_MSB_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00005FFC;  // Upper
localparam C_FRER_STATS_2_LSB_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00006000;  // Lower
localparam C_FRER_STATS_2_MSB_ADDR                 = C_SWITCH_CFG_BASE_OFFSET+32'h00007FFC;  // Upper

//scheduler interface bit map position
localparam SCHD_BIT_POSITION                       = 2;  // GATE[2] op
localparam RSV1_BIT_POSITION                       = 1;  // GATE[1] op
localparam BE_1_BIT_POSITION                       = 0;  // GATE[0] op
localparam RSV2_BIT_POSITION                       = 3;  // GATE[3] op
localparam BE_2_BIT_POSITION                       = 4;  // GATE[4] op
localparam BE_3_BIT_POSITION                       = 5;  // GATE[5] op
localparam BE_4_BIT_POSITION                       = 6;  // GATE[6] op
localparam BE_5_BIT_POSITION                       = 7;  // GATE[7] op

localparam EN_MGMT_ALL                             = 0;  // GATE[7] op
localparam EN_PSFP_SDU                             = 1;  // GATE[7] op
localparam EN_MGMT_STAT                            = 1;  // GATE[7] op

