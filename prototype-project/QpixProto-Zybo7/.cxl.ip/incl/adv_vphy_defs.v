// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

`ifndef __VID_PHY_DEFS__
`define __VID_PHY_DEFS__

`define tCTRL_SZ                                                     1125
`define tPHY_MEM_MAP_FIELDS_CONTROL(LI)                              [(``LI``*`tCTRL_SZ-1):0]

  `define RX_REFCLK_CEB(LI)                                          1124+(`tCTRL_SZ*``LI``)
  `define TX_REFCLK_CEB(LI)                                          1123+(`tCTRL_SZ*``LI``)

// START - additional for HDMI PHY
  `define MMCM_RXUSRCLK_LOCK_MASK(LI)                                1122+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_LOCK_MASK(LI)                                1121+(`tCTRL_SZ*``LI``)

  `define CH4_DRU_GAIN_G2(LI)                1120+(`tCTRL_SZ*``LI``):1116+(`tCTRL_SZ*``LI``)
  `define CH4_DRU_GAIN_G1_P(LI)              1115+(`tCTRL_SZ*``LI``):1111+(`tCTRL_SZ*``LI``)
  `define CH4_DRU_GAIN_G1(LI)                1110+(`tCTRL_SZ*``LI``):1106+(`tCTRL_SZ*``LI``)
  `define CH4_DRU_CENTER_FREQ(LI)            1105+(`tCTRL_SZ*``LI``):1069+(`tCTRL_SZ*``LI``)
  `define CH4_DRU_ENABLE(LI)                                         1068+(`tCTRL_SZ*``LI``)
  `define CH4_DRU_RESET(LI)                                          1067+(`tCTRL_SZ*``LI``)

  `define CH3_DRU_GAIN_G2(LI)                1066+(`tCTRL_SZ*``LI``):1062+(`tCTRL_SZ*``LI``)
  `define CH3_DRU_GAIN_G1_P(LI)              1061+(`tCTRL_SZ*``LI``):1057+(`tCTRL_SZ*``LI``)
  `define CH3_DRU_GAIN_G1(LI)                1056+(`tCTRL_SZ*``LI``):1052+(`tCTRL_SZ*``LI``)
  `define CH3_DRU_CENTER_FREQ(LI)            1051+(`tCTRL_SZ*``LI``):1015+(`tCTRL_SZ*``LI``)
  `define CH3_DRU_ENABLE(LI)                                         1014+(`tCTRL_SZ*``LI``)
  `define CH3_DRU_RESET(LI)                                          1013+(`tCTRL_SZ*``LI``)

  `define CH2_DRU_GAIN_G2(LI)                1012+(`tCTRL_SZ*``LI``):1008+(`tCTRL_SZ*``LI``)
  `define CH2_DRU_GAIN_G1_P(LI)              1007+(`tCTRL_SZ*``LI``):1003+(`tCTRL_SZ*``LI``)
  `define CH2_DRU_GAIN_G1(LI)                1002+(`tCTRL_SZ*``LI``):998+(`tCTRL_SZ*``LI``)
  `define CH2_DRU_CENTER_FREQ(LI)             997+(`tCTRL_SZ*``LI``):961+(`tCTRL_SZ*``LI``)
  `define CH2_DRU_ENABLE(LI)                                         960+(`tCTRL_SZ*``LI``)
  `define CH2_DRU_RESET(LI)                                          959+(`tCTRL_SZ*``LI``)

  `define CH1_DRU_GAIN_G2(LI)                 958+(`tCTRL_SZ*``LI``):954+(`tCTRL_SZ*``LI``)
  `define CH1_DRU_GAIN_G1_P(LI)               953+(`tCTRL_SZ*``LI``):949+(`tCTRL_SZ*``LI``)
  `define CH1_DRU_GAIN_G1(LI)                 948+(`tCTRL_SZ*``LI``):944+(`tCTRL_SZ*``LI``)
  `define CH1_DRU_CENTER_FREQ(LI)             943+(`tCTRL_SZ*``LI``):907+(`tCTRL_SZ*``LI``)
  `define CH1_DRU_ENABLE(LI)                                         906+(`tCTRL_SZ*``LI``)
  `define CH1_DRU_RESET(LI)                                          905+(`tCTRL_SZ*``LI``)

  `define CLKDET_RX_FREQ_EVENT_CLR(LI)                               904+(`tCTRL_SZ*``LI``)
  `define CLKDET_RX_TMR_EVENT_CLR(LI)                                903+(`tCTRL_SZ*``LI``)
  `define CLKDET_TX_FREQ_EVENT_CLR(LI)                               902+(`tCTRL_SZ*``LI``)
  `define CLKDET_TX_TMR_EVENT_CLR(LI)                                901+(`tCTRL_SZ*``LI``)
  `define CLKDET_RX_TMR_LOAD(LI)                                     900+(`tCTRL_SZ*``LI``)
  `define CLKDET_TX_TMR_LOAD(LI)                                     899+(`tCTRL_SZ*``LI``)
  `define CLKDET_RX_TMR_TMOUT_CNT(LI)         898+(`tCTRL_SZ*``LI``):867+(`tCTRL_SZ*``LI``)
  `define CLKDET_TX_TMR_TMOUT_CNT(LI)         866+(`tCTRL_SZ*``LI``):835+(`tCTRL_SZ*``LI``)
  `define CLKDET_FREQ_CNTR_TMOUT(LI)          834+(`tCTRL_SZ*``LI``):803+(`tCTRL_SZ*``LI``)
  `define CLKDET_FREQ_LOCK_CNTR_TRSHLD(LI)    802+(`tCTRL_SZ*``LI``):795+(`tCTRL_SZ*``LI``)
  `define CLKDET_RX_FREQ_RST(LI)                                     794+(`tCTRL_SZ*``LI``)
  `define CLKDET_TX_FREQ_RST(LI)                                     793+(`tCTRL_SZ*``LI``)
  `define CLKDET_RX_TMR_CLR(LI)                                      792+(`tCTRL_SZ*``LI``)
  `define CLKDET_TX_TMR_CLR(LI)                                      791+(`tCTRL_SZ*``LI``)
  `define CLKDET_RUN(LI)                                             790+(`tCTRL_SZ*``LI``)
  `define OBUFTDS_RXUSRCLK_CLKOUT1_EN(LI)                            789+(`tCTRL_SZ*``LI``)
  `define OBUFTDS_TXUSRCLK_CLKOUT1_EN(LI)                            788+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_POWER_DOWN(LI)                               787+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_POWER_DOWN(LI)                               786+(`tCTRL_SZ*``LI``)
  `define GTREFCLK1_CEB(LI)                                          785+(`tCTRL_SZ*``LI``)
  `define GTREFCLK0_CEB(LI)                                          784+(`tCTRL_SZ*``LI``)

// END - for HDMI PHY

  `define BUFGT_RXUSRCLK_DIV(LI)              783+(`tCTRL_SZ*``LI``):781+(`tCTRL_SZ*``LI``)
  `define BUFGT_RXUSRCLK_CLEAR(LI)                                   780+(`tCTRL_SZ*``LI``)
  `define BUFGT_TXUSRCLK_DIV(LI)              779+(`tCTRL_SZ*``LI``):777+(`tCTRL_SZ*``LI``)
  `define BUFGT_TXUSRCLK_CLEAR(LI)                                   776+(`tCTRL_SZ*``LI``)

  `define MMCM_RXUSRCLK_CONFIG_RESET(LI)                             775+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_CONFIG_START(LI)                             774+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_CLKOUT0_FRAC(LI)      773+(`tCTRL_SZ*``LI``):764+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_CLKOUT0_DIVIDE(LI)    763+(`tCTRL_SZ*``LI``):756+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_CLKOUT1_DIVIDE(LI)    755+(`tCTRL_SZ*``LI``):748+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_CLKOUT2_DIVIDE(LI)    747+(`tCTRL_SZ*``LI``):740+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_CLKFBOUT_FRAC(LI)     739+(`tCTRL_SZ*``LI``):730+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_CLKFBOUT_MULT(LI)     729+(`tCTRL_SZ*``LI``):722+(`tCTRL_SZ*``LI``)
  `define MMCM_RXUSRCLK_DIVCLK_DIV(LI)        721+(`tCTRL_SZ*``LI``):714+(`tCTRL_SZ*``LI``)

  `define MMCM_TXUSRCLK_CONFIG_RESET(LI)                             713+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_CONFIG_START(LI)                             712+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_CLKOUT0_FRAC(LI)      711+(`tCTRL_SZ*``LI``):702+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_CLKOUT0_DIVIDE(LI)    701+(`tCTRL_SZ*``LI``):694+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_CLKOUT1_DIVIDE(LI)    693+(`tCTRL_SZ*``LI``):686+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_CLKOUT2_DIVIDE(LI)    685+(`tCTRL_SZ*``LI``):678+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_CLKFBOUT_FRAC(LI)     677+(`tCTRL_SZ*``LI``):668+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_CLKFBOUT_MULT(LI)     667+(`tCTRL_SZ*``LI``):660+(`tCTRL_SZ*``LI``)
  `define MMCM_TXUSRCLK_DIVCLK_DIV(LI)        659+(`tCTRL_SZ*``LI``):652+(`tCTRL_SZ*``LI``)

  `define CH4_RX_PLL_GT_RST(LI)                                      651+(`tCTRL_SZ*``LI``)
  `define CH3_RX_PLL_GT_RST(LI)                                      650+(`tCTRL_SZ*``LI``)
  `define CH2_RX_PLL_GT_RST(LI)                                      649+(`tCTRL_SZ*``LI``)
  `define CH1_RX_PLL_GT_RST(LI)                                      648+(`tCTRL_SZ*``LI``)

  `define CH4_TX_PLL_GT_RST(LI)                                      647+(`tCTRL_SZ*``LI``)
  `define CH3_TX_PLL_GT_RST(LI)                                      646+(`tCTRL_SZ*``LI``)
  `define CH2_TX_PLL_GT_RST(LI)                                      645+(`tCTRL_SZ*``LI``)
  `define CH1_TX_PLL_GT_RST(LI)                                      644+(`tCTRL_SZ*``LI``)

  `define CTRL_RESERVED5(LI)                  643+(`tCTRL_SZ*``LI``):584+(`tCTRL_SZ*``LI``)
  
  `define RX_TDLOCK_VALUE(LI)                 583+(`tCTRL_SZ*``LI``):552+(`tCTRL_SZ*``LI``)

  `define CH4_RXLPMHFOVRDEN(LI)                                      551+(`tCTRL_SZ*``LI``)
  `define CH4_RXLPMLFKLOVRDEN(LI)                                    550+(`tCTRL_SZ*``LI``)
  `define CH4_RXOSOVRDEN(LI)                                         549+(`tCTRL_SZ*``LI``)
  `define CH4_RXCDRHOLD(LI)                                          548+(`tCTRL_SZ*``LI``)
  `define CH4_RXLPMEN(LI)                                            547+(`tCTRL_SZ*``LI``)

  `define CH3_RXLPMHFOVRDEN(LI)                                      546+(`tCTRL_SZ*``LI``)
  `define CH3_RXLPMLFKLOVRDEN(LI)                                    545+(`tCTRL_SZ*``LI``)
  `define CH3_RXOSOVRDEN(LI)                                         544+(`tCTRL_SZ*``LI``)
  `define CH3_RXCDRHOLD(LI)                                          543+(`tCTRL_SZ*``LI``)
  `define CH3_RXLPMEN(LI)                                            542+(`tCTRL_SZ*``LI``)

  `define CH2_RXLPMHFOVRDEN(LI)                                      541+(`tCTRL_SZ*``LI``)
  `define CH2_RXLPMLFKLOVRDEN(LI)                                    540+(`tCTRL_SZ*``LI``)
  `define CH2_RXOSOVRDEN(LI)                                         539+(`tCTRL_SZ*``LI``)
  `define CH2_RXCDRHOLD(LI)                                          538+(`tCTRL_SZ*``LI``)
  `define CH2_RXLPMEN(LI)                                            537+(`tCTRL_SZ*``LI``)

  `define CH1_RXLPMHFOVRDEN(LI)                                      536+(`tCTRL_SZ*``LI``)
  `define CH1_RXLPMLFKLOVRDEN(LI)                                    535+(`tCTRL_SZ*``LI``)
  `define CH1_RXOSOVRDEN(LI)                                         534+(`tCTRL_SZ*``LI``)
  `define CH1_RXCDRHOLD(LI)                                          533+(`tCTRL_SZ*``LI``)
  `define CH1_RXLPMEN(LI)                                            532+(`tCTRL_SZ*``LI``)

  `define CH4_RXPRBSSEL(LI)                   531+(`tCTRL_SZ*``LI``):528+(`tCTRL_SZ*``LI``)
  `define CH4_RXPRBSCNTRESET(LI)                                     527+(`tCTRL_SZ*``LI``)
  `define CH4_RXPOLARITY(LI)                                         526+(`tCTRL_SZ*``LI``)
  `define CH4_RX8B10BEN(LI)                                          525+(`tCTRL_SZ*``LI``)

  `define CH3_RXPRBSSEL(LI)                   524+(`tCTRL_SZ*``LI``):521+(`tCTRL_SZ*``LI``)
  `define CH3_RXPRBSCNTRESET(LI)                                     520+(`tCTRL_SZ*``LI``)
  `define CH3_RXPOLARITY(LI)                                         519+(`tCTRL_SZ*``LI``)
  `define CH3_RX8B10BEN(LI)                                          518+(`tCTRL_SZ*``LI``)

  `define CH2_RXPRBSSEL(LI)                   517+(`tCTRL_SZ*``LI``):514+(`tCTRL_SZ*``LI``)
  `define CH2_RXPRBSCNTRESET(LI)                                     513+(`tCTRL_SZ*``LI``)
  `define CH2_RXPOLARITY(LI)                                         512+(`tCTRL_SZ*``LI``)
  `define CH2_RX8B10BEN(LI)                                          511+(`tCTRL_SZ*``LI``)

  `define CH1_RXPRBSSEL(LI)                   510+(`tCTRL_SZ*``LI``):507+(`tCTRL_SZ*``LI``)
  `define CH1_RXPRBSCNTRESET(LI)                                     506+(`tCTRL_SZ*``LI``)
  `define CH1_RXPOLARITY(LI)                                         505+(`tCTRL_SZ*``LI``)
  `define CH1_RX8B10BEN(LI)                                          504+(`tCTRL_SZ*``LI``)

  `define CH4_TXPRECURSOR(LI)                 503+(`tCTRL_SZ*``LI``):499+(`tCTRL_SZ*``LI``)
  `define CH4_TXPOSTCURSOR(LI)                498+(`tCTRL_SZ*``LI``):494+(`tCTRL_SZ*``LI``)
  `define CH4_TXINHIBIT(LI)                                          493+(`tCTRL_SZ*``LI``)
  `define CH4_TXELECIDLE(LI)                                         492+(`tCTRL_SZ*``LI``)
  `define CH4_TXDIFFCTRL(LI)                  491+(`tCTRL_SZ*``LI``):488+(`tCTRL_SZ*``LI``)

  `define CH3_TXPRECURSOR(LI)                 487+(`tCTRL_SZ*``LI``):483+(`tCTRL_SZ*``LI``)
  `define CH3_TXPOSTCURSOR(LI)                482+(`tCTRL_SZ*``LI``):478+(`tCTRL_SZ*``LI``)
  `define CH3_TXINHIBIT(LI)                                          477+(`tCTRL_SZ*``LI``)
  `define CH3_TXELECIDLE(LI)                                         476+(`tCTRL_SZ*``LI``)
  `define CH3_TXDIFFCTRL(LI)                  475+(`tCTRL_SZ*``LI``):472+(`tCTRL_SZ*``LI``)

  `define CH2_TXPRECURSOR(LI)                 471+(`tCTRL_SZ*``LI``):467+(`tCTRL_SZ*``LI``)
  `define CH2_TXPOSTCURSOR(LI)                466+(`tCTRL_SZ*``LI``):462+(`tCTRL_SZ*``LI``)
  `define CH2_TXINHIBIT(LI)                                          461+(`tCTRL_SZ*``LI``)
  `define CH2_TXELECIDLE(LI)                                         460+(`tCTRL_SZ*``LI``)
  `define CH2_TXDIFFCTRL(LI)                  459+(`tCTRL_SZ*``LI``):456+(`tCTRL_SZ*``LI``)

  `define CH1_TXPRECURSOR(LI)                 455+(`tCTRL_SZ*``LI``):451+(`tCTRL_SZ*``LI``)
  `define CH1_TXPOSTCURSOR(LI)                450+(`tCTRL_SZ*``LI``):446+(`tCTRL_SZ*``LI``)
  `define CH1_TXINHIBIT(LI)                                          445+(`tCTRL_SZ*``LI``)
  `define CH1_TXELECIDLE(LI)                                         444+(`tCTRL_SZ*``LI``)
  `define CH1_TXDIFFCTRL(LI)                  443+(`tCTRL_SZ*``LI``):440+(`tCTRL_SZ*``LI``)

  `define CH4_TXDLYEN(LI)                                            439+(`tCTRL_SZ*``LI``)
  `define CH4_TXDLYBYPASS(LI)                                        438+(`tCTRL_SZ*``LI``)
  `define CH4_TXDLYRESET(LI)                                         437+(`tCTRL_SZ*``LI``)
  `define CH4_TXPHINIT(LI)                                           436+(`tCTRL_SZ*``LI``)
  `define CH4_TXPHDLYPD(LI)                                          435+(`tCTRL_SZ*``LI``)
  `define CH4_TXPHALIGNEN(LI)                                        434+(`tCTRL_SZ*``LI``)
  `define CH4_TXPHALIGN(LI)                                          433+(`tCTRL_SZ*``LI``)
  `define CH4_TXPHDLYRESET(LI)                                       432+(`tCTRL_SZ*``LI``)

  `define CH3_TXDLYEN(LI)                                            431+(`tCTRL_SZ*``LI``)
  `define CH3_TXDLYBYPASS(LI)                                        430+(`tCTRL_SZ*``LI``)
  `define CH3_TXDLYRESET(LI)                                         429+(`tCTRL_SZ*``LI``)
  `define CH3_TXPHINIT(LI)                                           428+(`tCTRL_SZ*``LI``)
  `define CH3_TXPHDLYPD(LI)                                          427+(`tCTRL_SZ*``LI``)
  `define CH3_TXPHALIGNEN(LI)                                        426+(`tCTRL_SZ*``LI``)
  `define CH3_TXPHALIGN(LI)                                          425+(`tCTRL_SZ*``LI``)
  `define CH3_TXPHDLYRESET(LI)                                       424+(`tCTRL_SZ*``LI``)

  `define CH2_TXDLYEN(LI)                                            423+(`tCTRL_SZ*``LI``)
  `define CH2_TXDLYBYPASS(LI)                                        422+(`tCTRL_SZ*``LI``)
  `define CH2_TXDLYRESET(LI)                                         421+(`tCTRL_SZ*``LI``)
  `define CH2_TXPHINIT(LI)                                           420+(`tCTRL_SZ*``LI``)
  `define CH2_TXPHDLYPD(LI)                                          419+(`tCTRL_SZ*``LI``)
  `define CH2_TXPHALIGNEN(LI)                                        418+(`tCTRL_SZ*``LI``)
  `define CH2_TXPHALIGN(LI)                                          417+(`tCTRL_SZ*``LI``)
  `define CH2_TXPHDLYRESET(LI)                                       416+(`tCTRL_SZ*``LI``)

  `define CH1_TXDLYEN(LI)                                            415+(`tCTRL_SZ*``LI``)
  `define CH1_TXDLYBYPASS(LI)                                        414+(`tCTRL_SZ*``LI``)
  `define CH1_TXDLYRESET(LI)                                         413+(`tCTRL_SZ*``LI``)
  `define CH1_TXPHINIT(LI)                                           412+(`tCTRL_SZ*``LI``)
  `define CH1_TXPHDLYPD(LI)                                          411+(`tCTRL_SZ*``LI``)
  `define CH1_TXPHALIGNEN(LI)                                        410+(`tCTRL_SZ*``LI``)
  `define CH1_TXPHALIGN(LI)                                          409+(`tCTRL_SZ*``LI``)
  `define CH1_TXPHDLYRESET(LI)                                       408+(`tCTRL_SZ*``LI``)

  `define CH4_TXPRBSFORCEERR(LI)                                     407+(`tCTRL_SZ*``LI``)
  `define CH4_TXPRBSSEL(LI)                   406+(`tCTRL_SZ*``LI``):403+(`tCTRL_SZ*``LI``)
  `define CH4_TXPOLARITY(LI)                                         402+(`tCTRL_SZ*``LI``)
  `define CH4_TX8B10BEN(LI)                                          401+(`tCTRL_SZ*``LI``)

  `define CH3_TXPRBSFORCEERR(LI)                                     400+(`tCTRL_SZ*``LI``)
  `define CH3_TXPRBSSEL(LI)                   399+(`tCTRL_SZ*``LI``):396+(`tCTRL_SZ*``LI``)
  `define CH3_TXPOLARITY(LI)                                         395+(`tCTRL_SZ*``LI``)
  `define CH3_TX8B10BEN(LI)                                          394+(`tCTRL_SZ*``LI``)

  `define CH2_TXPRBSFORCEERR(LI)                                     393+(`tCTRL_SZ*``LI``)
  `define CH2_TXPRBSSEL(LI)                   392+(`tCTRL_SZ*``LI``):389+(`tCTRL_SZ*``LI``)
  `define CH2_TXPOLARITY(LI)                                         388+(`tCTRL_SZ*``LI``)
  `define CH2_TX8B10BEN(LI)                                          387+(`tCTRL_SZ*``LI``)

  `define CH1_TXPRBSFORCEERR(LI)                                     386+(`tCTRL_SZ*``LI``)
  `define CH1_TXPRBSSEL(LI)                   385+(`tCTRL_SZ*``LI``):382+(`tCTRL_SZ*``LI``)
  `define CH1_TXPOLARITY(LI)                                         381+(`tCTRL_SZ*``LI``)
  `define CH1_TX8B10BEN(LI)                                          380+(`tCTRL_SZ*``LI``)

  `define CTRL_RESERVED4(LI)                  379+(`tCTRL_SZ*``LI``):188+(`tCTRL_SZ*``LI``)

  `define DRP_WREN_MASK(LI)                   187+(`tCTRL_SZ*``LI``):172+(`tCTRL_SZ*``LI``)
  `define CMN_DRP_TXN(LI)                                            171+(`tCTRL_SZ*``LI``)
  `define CH4_RXDRP_TXN(LI)                                          170+(`tCTRL_SZ*``LI``)
  `define CH3_RXDRP_TXN(LI)                                          169+(`tCTRL_SZ*``LI``)
  `define CH2_RXDRP_TXN(LI)                                          168+(`tCTRL_SZ*``LI``)
  `define CH1_RXDRP_TXN(LI)                                          167+(`tCTRL_SZ*``LI``)
  `define CH4_TXDRP_TXN(LI)                                          166+(`tCTRL_SZ*``LI``)
  `define CH3_TXDRP_TXN(LI)                                          165+(`tCTRL_SZ*``LI``)
  `define CH2_TXDRP_TXN(LI)                                          164+(`tCTRL_SZ*``LI``)
  `define CH1_TXDRP_TXN(LI)                                          163+(`tCTRL_SZ*``LI``)

  `define DRPDI(LI)                           162+(`tCTRL_SZ*``LI``):147+(`tCTRL_SZ*``LI``)
  `define DRPRST(LI)                                                 146+(`tCTRL_SZ*``LI``)
  `define DRPWE(LI)                                                  145+(`tCTRL_SZ*``LI``)
  `define DRPEN(LI)                                                  144+(`tCTRL_SZ*``LI``)
  `define DRPADDR(LI)                         143+(`tCTRL_SZ*``LI``):132+(`tCTRL_SZ*``LI``)

  `define CH4_LOOPBACK(LI)                    131+(`tCTRL_SZ*``LI``):129+(`tCTRL_SZ*``LI``)
  `define CH3_LOOPBACK(LI)                    128+(`tCTRL_SZ*``LI``):126+(`tCTRL_SZ*``LI``)
  `define CH2_LOOPBACK(LI)                    125+(`tCTRL_SZ*``LI``):123+(`tCTRL_SZ*``LI``)
  `define CH1_LOOPBACK(LI)                    122+(`tCTRL_SZ*``LI``):120+(`tCTRL_SZ*``LI``)

  `define CH4_TXPD(LI)                        119+(`tCTRL_SZ*``LI``):118+(`tCTRL_SZ*``LI``)
  `define CH4_RXPD(LI)                        117+(`tCTRL_SZ*``LI``):116+(`tCTRL_SZ*``LI``)
  `define CH4_TXCPLLPD(LI)                                           115+(`tCTRL_SZ*``LI``)
  `define CH4_RXCPLLPD(LI)                                           114+(`tCTRL_SZ*``LI``)

  `define CH3_TXPD(LI)                        113+(`tCTRL_SZ*``LI``):112+(`tCTRL_SZ*``LI``)
  `define CH3_RXPD(LI)                        111+(`tCTRL_SZ*``LI``):110+(`tCTRL_SZ*``LI``)
  `define CH3_TXCPLLPD(LI)                                           109+(`tCTRL_SZ*``LI``)
  `define CH3_RXCPLLPD(LI)                                           108+(`tCTRL_SZ*``LI``)

  `define CH2_TXPD(LI)                        107+(`tCTRL_SZ*``LI``):106+(`tCTRL_SZ*``LI``)
  `define CH2_RXPD(LI)                        105+(`tCTRL_SZ*``LI``):104+(`tCTRL_SZ*``LI``)
  `define CH2_TXCPLLPD(LI)                                           103+(`tCTRL_SZ*``LI``)
  `define CH2_RXCPLLPD(LI)                                           102+(`tCTRL_SZ*``LI``)

  `define CH1_TXPD(LI)                        101+(`tCTRL_SZ*``LI``):100+(`tCTRL_SZ*``LI``)
  `define CH1_RXPD(LI)                         99+(`tCTRL_SZ*``LI``): 98+(`tCTRL_SZ*``LI``)
  `define CH1_TXCPLLPD(LI)                                            97+(`tCTRL_SZ*``LI``)
  `define CH1_RXCPLLPD(LI)                                            96+(`tCTRL_SZ*``LI``)

  `define CTRL_RESERVED3(LI)                   95+(`tCTRL_SZ*``LI``): 94+(`tCTRL_SZ*``LI``)
  `define QPLL1PD(LI)                                                 93+(`tCTRL_SZ*``LI``)
  `define QPLL0PD(LI)                                                 92+(`tCTRL_SZ*``LI``)

  `define CH4_RXUSERRDY(LI)                                           91+(`tCTRL_SZ*``LI``)
  `define CH4_RXBUFRESET(LI)                                          90+(`tCTRL_SZ*``LI``)
  `define CH4_RXPCSRESET(LI)                                          89+(`tCTRL_SZ*``LI``)
  `define CH4_EYESCANRESET(LI)                                        88+(`tCTRL_SZ*``LI``)
  `define CH4_RXDFELPMRESET(LI)                                       87+(`tCTRL_SZ*``LI``)
  `define CH4_RXPMARESET(LI)                                          86+(`tCTRL_SZ*``LI``)
  `define CH4_GTRXRESET(LI)                                           85+(`tCTRL_SZ*``LI``)

  `define CH3_RXUSERRDY(LI)                                           84+(`tCTRL_SZ*``LI``)
  `define CH3_RXBUFRESET(LI)                                          83+(`tCTRL_SZ*``LI``)
  `define CH3_RXPCSRESET(LI)                                          82+(`tCTRL_SZ*``LI``)
  `define CH3_EYESCANRESET(LI)                                        81+(`tCTRL_SZ*``LI``)
  `define CH3_RXDFELPMRESET(LI)                                       80+(`tCTRL_SZ*``LI``)
  `define CH3_RXPMARESET(LI)                                          79+(`tCTRL_SZ*``LI``)
  `define CH3_GTRXRESET(LI)                                           78+(`tCTRL_SZ*``LI``)

  `define CH2_RXUSERRDY(LI)                                           77+(`tCTRL_SZ*``LI``)
  `define CH2_RXBUFRESET(LI)                                          76+(`tCTRL_SZ*``LI``)
  `define CH2_RXPCSRESET(LI)                                          75+(`tCTRL_SZ*``LI``)
  `define CH2_EYESCANRESET(LI)                                        74+(`tCTRL_SZ*``LI``)
  `define CH2_RXDFELPMRESET(LI)                                       73+(`tCTRL_SZ*``LI``)
  `define CH2_RXPMARESET(LI)                                          72+(`tCTRL_SZ*``LI``)
  `define CH2_GTRXRESET(LI)                                           71+(`tCTRL_SZ*``LI``)

  `define CH1_RXUSERRDY(LI)                                           70+(`tCTRL_SZ*``LI``)
  `define CH1_RXBUFRESET(LI)                                          69+(`tCTRL_SZ*``LI``)
  `define CH1_RXPCSRESET(LI)                                          68+(`tCTRL_SZ*``LI``)
  `define CH1_EYESCANRESET(LI)                                        67+(`tCTRL_SZ*``LI``)
  `define CH1_RXDFELPMRESET(LI)                                       66+(`tCTRL_SZ*``LI``)
  `define CH1_RXPMARESET(LI)                                          65+(`tCTRL_SZ*``LI``)
  `define CH1_GTRXRESET(LI)                                           64+(`tCTRL_SZ*``LI``)

  `define CH4_TXUSERRDY(LI)                                           63+(`tCTRL_SZ*``LI``)
  `define CH4_TXPCSRESET(LI)                                          62+(`tCTRL_SZ*``LI``)
  `define CH4_TXPMARESET(LI)                                          61+(`tCTRL_SZ*``LI``)
  `define CH4_GTTXRESET(LI)                                           60+(`tCTRL_SZ*``LI``)

  `define CH3_TXUSERRDY(LI)                                           59+(`tCTRL_SZ*``LI``)
  `define CH3_TXPCSRESET(LI)                                          58+(`tCTRL_SZ*``LI``)
  `define CH3_TXPMARESET(LI)                                          57+(`tCTRL_SZ*``LI``)
  `define CH3_GTTXRESET(LI)                                           56+(`tCTRL_SZ*``LI``)

  `define CH2_TXUSERRDY(LI)                                           55+(`tCTRL_SZ*``LI``)
  `define CH2_TXPCSRESET(LI)                                          54+(`tCTRL_SZ*``LI``)
  `define CH2_TXPMARESET(LI)                                          53+(`tCTRL_SZ*``LI``)
  `define CH2_GTTXRESET(LI)                                           52+(`tCTRL_SZ*``LI``)

  `define CH1_TXUSERRDY(LI)                                           51+(`tCTRL_SZ*``LI``)
  `define CH1_TXPCSRESET(LI)                                          50+(`tCTRL_SZ*``LI``)
  `define CH1_TXPMARESET(LI)                                          49+(`tCTRL_SZ*``LI``)
  `define CH1_GTTXRESET(LI)                                           48+(`tCTRL_SZ*``LI``)

  `define CTRL_RESERVED2(LI)                   47+(`tCTRL_SZ*``LI``): 46+(`tCTRL_SZ*``LI``)
  `define RXCPLLRESET(LI)                                             45+(`tCTRL_SZ*``LI``)
  `define QPLL1RESET(LI)                                              44+(`tCTRL_SZ*``LI``)
  `define QPLL0RESET(LI)                                              43+(`tCTRL_SZ*``LI``)
  `define TXCPLLRESET(LI)                                             42+(`tCTRL_SZ*``LI``)

  `define RXPLLCLKSEL(LI)                      41+(`tCTRL_SZ*``LI``): 40+(`tCTRL_SZ*``LI``)
  `define TXPLLCLKSEL(LI)                      39+(`tCTRL_SZ*``LI``): 38+(`tCTRL_SZ*``LI``)
  `define RXSYSCLKSEL(LI)                      37+(`tCTRL_SZ*``LI``): 36+(`tCTRL_SZ*``LI``)
  `define TXSYSCLKSEL(LI)                      35+(`tCTRL_SZ*``LI``): 34+(`tCTRL_SZ*``LI``)
  `define CTRL_RESERVED1(LI)                   33+(`tCTRL_SZ*``LI``): 30+(`tCTRL_SZ*``LI``)
  `define RXCPLLREFCLKSEL(LI)                  29+(`tCTRL_SZ*``LI``): 26+(`tCTRL_SZ*``LI``)
  `define CTRL_RESERVED0(LI)                   25+(`tCTRL_SZ*``LI``): 22+(`tCTRL_SZ*``LI``)
  `define QPLL1REFCLKSEL(LI)                   21+(`tCTRL_SZ*``LI``): 18+(`tCTRL_SZ*``LI``)
  `define TXCPLLREFCLKSEL(LI)                  17+(`tCTRL_SZ*``LI``): 14+(`tCTRL_SZ*``LI``)
  `define QPLL0REFCLKSEL(LI)                   13+(`tCTRL_SZ*``LI``): 10+(`tCTRL_SZ*``LI``)

  `define LI_RSVD_SEL(LI)                       9+(`tCTRL_SZ*``LI``):  4+(`tCTRL_SZ*``LI``)
  `define LI_TXRX_SEL(LI)                                              4+(`tCTRL_SZ*``LI``)
  `define LI_PAGE_SEL(LI)                       3+(`tCTRL_SZ*``LI``):  0+(`tCTRL_SZ*``LI``)


`define tSTAT_SZ                                                     445
`define tPHY_MEM_MAP_FIELDS_STATUS(LI)                             [(``LI``*`tSTAT_SZ-1):0]

  `define DRU_VERSION(LI)                     444+(`tSTAT_SZ*``LI``):437+(`tSTAT_SZ*``LI``)
  `define CH4_DRU_ACTIVE(LI)                                         436+(`tSTAT_SZ*``LI``)
  `define CH3_DRU_ACTIVE(LI)                                         435+(`tSTAT_SZ*``LI``)
  `define CH2_DRU_ACTIVE(LI)                                         434+(`tSTAT_SZ*``LI``)
  `define CH1_DRU_ACTIVE(LI)                                         433+(`tSTAT_SZ*``LI``)

  `define CLKDET_RX_FREQ_EVENT(LI)                                   432+(`tSTAT_SZ*``LI``)
  `define CLKDET_RX_TMR_EVENT(LI)                                    431+(`tSTAT_SZ*``LI``)
  `define CLKDET_TX_FREQ_EVENT(LI)                                   430+(`tSTAT_SZ*``LI``)
  `define CLKDET_TX_TMR_EVENT(LI)                                    429+(`tSTAT_SZ*``LI``)
  `define CLKDET_DRU_FREQ(LI)                 428+(`tSTAT_SZ*``LI``):397+(`tSTAT_SZ*``LI``)
  `define CLKDET_RX_FREQ(LI)                  396+(`tSTAT_SZ*``LI``):365+(`tSTAT_SZ*``LI``)
  `define CLKDET_TX_FREQ(LI)                  364+(`tSTAT_SZ*``LI``):333+(`tSTAT_SZ*``LI``)
  `define CLKDET_TX_REFCLK_LOCK_CAP(LI)                              332+(`tSTAT_SZ*``LI``)
  `define CLKDET_TX_REFCLK_LOCK(LI)                                  331+(`tSTAT_SZ*``LI``)
  `define CLKDET_RX_FREQ_ZERO(LI)                                    330+(`tSTAT_SZ*``LI``)
  `define CLKDET_TX_FREQ_ZERO(LI)                                    329+(`tSTAT_SZ*``LI``)

  `define CH4_SYM_ERR_COUNT(LI)               328+(`tSTAT_SZ*``LI``):313+(`tSTAT_SZ*``LI``)
  `define CH3_SYM_ERR_COUNT(LI)               312+(`tSTAT_SZ*``LI``):297+(`tSTAT_SZ*``LI``)
  `define CH2_SYM_ERR_COUNT(LI)               296+(`tSTAT_SZ*``LI``):281+(`tSTAT_SZ*``LI``)
  `define CH1_SYM_ERR_COUNT(LI)               280+(`tSTAT_SZ*``LI``):265+(`tSTAT_SZ*``LI``)

  `define CH4_BUFF_BYPASS_TX_ERR(LI)                                 264+(`tSTAT_SZ*``LI``)
  `define CH3_BUFF_BYPASS_TX_ERR(LI)                                 263+(`tSTAT_SZ*``LI``)
  `define CH2_BUFF_BYPASS_TX_ERR(LI)                                 262+(`tSTAT_SZ*``LI``)
  `define CH1_BUFF_BYPASS_TX_ERR(LI)                                 261+(`tSTAT_SZ*``LI``)

  `define CH4_RXCPLLLOCK(LI)                                         260+(`tSTAT_SZ*``LI``)
  `define CH3_RXCPLLLOCK(LI)                                         259+(`tSTAT_SZ*``LI``)
  `define CH2_RXCPLLLOCK(LI)                                         258+(`tSTAT_SZ*``LI``)
  `define CH1_RXCPLLLOCK(LI)                                         257+(`tSTAT_SZ*``LI``)

  `define CH4_TXCPLLLOCK(LI)                                         256+(`tSTAT_SZ*``LI``)
  `define CH3_TXCPLLLOCK(LI)                                         255+(`tSTAT_SZ*``LI``)
  `define CH2_TXCPLLLOCK(LI)                                         254+(`tSTAT_SZ*``LI``)
  `define CH1_TXCPLLLOCK(LI)                                         253+(`tSTAT_SZ*``LI``)

  `define MMCM_RXUSRCLK_LOCKED(LI)                                   252+(`tSTAT_SZ*``LI``)
  `define MMCM_RXUSRCLK_CONFIG_DONE(LI)                              251+(`tSTAT_SZ*``LI``)
  `define MMCM_TXUSRCLK_LOCKED(LI)                                   250+(`tSTAT_SZ*``LI``)
  `define MMCM_TXUSRCLK_CONFIG_DONE(LI)                              249+(`tSTAT_SZ*``LI``)

  `define CH4_RXPRBSERR(LI)                                          248+(`tSTAT_SZ*``LI``)
  `define CH3_RXPRBSERR(LI)                                          247+(`tSTAT_SZ*``LI``)
  `define CH2_RXPRBSERR(LI)                                          246+(`tSTAT_SZ*``LI``)
  `define CH1_RXPRBSERR(LI)                                          245+(`tSTAT_SZ*``LI``)

  `define CH4_RXBUFSTATUS(LI)                 244+(`tSTAT_SZ*``LI``):242+(`tSTAT_SZ*``LI``)
  `define CH4_RXCDRLOCK(LI)                                          241+(`tSTAT_SZ*``LI``)

  `define CH3_RXBUFSTATUS(LI)                 240+(`tSTAT_SZ*``LI``):238+(`tSTAT_SZ*``LI``)
  `define CH3_RXCDRLOCK(LI)                                          237+(`tSTAT_SZ*``LI``)

  `define CH2_RXBUFSTATUS(LI)                 236+(`tSTAT_SZ*``LI``):234+(`tSTAT_SZ*``LI``)
  `define CH2_RXCDRLOCK(LI)                                          233+(`tSTAT_SZ*``LI``)

  `define CH1_RXBUFSTATUS(LI)                 232+(`tSTAT_SZ*``LI``):230+(`tSTAT_SZ*``LI``)
  `define CH1_RXCDRLOCK(LI)                                          229+(`tSTAT_SZ*``LI``)

  `define CH4_TXBUFSTATUS(LI)                 228+(`tSTAT_SZ*``LI``):227+(`tSTAT_SZ*``LI``)
  `define CH4_TXDLYRESETDONE(LI)                                     226+(`tSTAT_SZ*``LI``)
  `define CH4_TXPHINITDONE(LI)                                       225+(`tSTAT_SZ*``LI``)
  `define CH4_TXPHALIGNDONE(LI)                                      224+(`tSTAT_SZ*``LI``)

  `define CH3_TXBUFSTATUS(LI)                 223+(`tSTAT_SZ*``LI``):222+(`tSTAT_SZ*``LI``)
  `define CH3_TXDLYRESETDONE(LI)                                     221+(`tSTAT_SZ*``LI``)
  `define CH3_TXPHINITDONE(LI)                                       220+(`tSTAT_SZ*``LI``)
  `define CH3_TXPHALIGNDONE(LI)                                      219+(`tSTAT_SZ*``LI``)

  `define CH2_TXBUFSTATUS(LI)                 218+(`tSTAT_SZ*``LI``):217+(`tSTAT_SZ*``LI``)
  `define CH2_TXDLYRESETDONE(LI)                                     216+(`tSTAT_SZ*``LI``)
  `define CH2_TXPHINITDONE(LI)                                       215+(`tSTAT_SZ*``LI``)
  `define CH2_TXPHALIGNDONE(LI)                                      214+(`tSTAT_SZ*``LI``)

  `define CH1_TXBUFSTATUS(LI)                 213+(`tSTAT_SZ*``LI``):212+(`tSTAT_SZ*``LI``)
  `define CH1_TXDLYRESETDONE(LI)                                     211+(`tSTAT_SZ*``LI``)
  `define CH1_TXPHINITDONE(LI)                                       210+(`tSTAT_SZ*``LI``)
  `define CH1_TXPHALIGNDONE(LI)                                      209+(`tSTAT_SZ*``LI``)

  `define CH4_RXPRBLOCKED(LI)                                        208+(`tSTAT_SZ*``LI``)
  `define CH3_RXPRBLOCKED(LI)                                        207+(`tSTAT_SZ*``LI``)
  `define CH2_RXPRBLOCKED(LI)                                        206+(`tSTAT_SZ*``LI``)
  `define CH1_RXPRBLOCKED(LI)                                        205+(`tSTAT_SZ*``LI``)

  `define STAT_RESERVED1(LI)                  204+(`tSTAT_SZ*``LI``):191+(`tSTAT_SZ*``LI``)

  `define COMMON_DRPBUSY(LI)                                         190+(`tSTAT_SZ*``LI``)
  `define COMMON_DRPRDY(LI)                                          189+(`tSTAT_SZ*``LI``)
  `define COMMON_DRPDO(LI)                    188+(`tSTAT_SZ*``LI``):173+(`tSTAT_SZ*``LI``)

  `define CH4_RXDRPBUSY(LI)                                          172+(`tSTAT_SZ*``LI``)
  `define CH4_RXDRPRDY(LI)                                           171+(`tSTAT_SZ*``LI``)
  `define CH4_RXDRPDO(LI)                     170+(`tSTAT_SZ*``LI``):155+(`tSTAT_SZ*``LI``)

  `define CH3_RXDRPBUSY(LI)                                          154+(`tSTAT_SZ*``LI``)
  `define CH3_RXDRPRDY(LI)                                           153+(`tSTAT_SZ*``LI``)
  `define CH3_RXDRPDO(LI)                     152+(`tSTAT_SZ*``LI``):137+(`tSTAT_SZ*``LI``)

  `define CH2_RXDRPBUSY(LI)                                          136+(`tSTAT_SZ*``LI``)
  `define CH2_RXDRPRDY(LI)                                           135+(`tSTAT_SZ*``LI``)
  `define CH2_RXDRPDO(LI)                     134+(`tSTAT_SZ*``LI``):119+(`tSTAT_SZ*``LI``)

  `define CH1_RXDRPBUSY(LI)                                          118+(`tSTAT_SZ*``LI``)
  `define CH1_RXDRPRDY(LI)                                           117+(`tSTAT_SZ*``LI``)
  `define CH1_RXDRPDO(LI)                     116+(`tSTAT_SZ*``LI``):101+(`tSTAT_SZ*``LI``)

  `define CH4_TXDRPBUSY(LI)                                          100+(`tSTAT_SZ*``LI``)
  `define CH4_TXDRPRDY(LI)                                            99+(`tSTAT_SZ*``LI``)
  `define CH4_TXDRPDO(LI)                      98+(`tSTAT_SZ*``LI``): 83+(`tSTAT_SZ*``LI``)

  `define CH3_TXDRPBUSY(LI)                                           82+(`tSTAT_SZ*``LI``)
  `define CH3_TXDRPRDY(LI)                                            81+(`tSTAT_SZ*``LI``)
  `define CH3_TXDRPDO(LI)                      80+(`tSTAT_SZ*``LI``): 65+(`tSTAT_SZ*``LI``)

  `define CH2_TXDRPBUSY(LI)                                           64+(`tSTAT_SZ*``LI``)
  `define CH2_TXDRPRDY(LI)                                            63+(`tSTAT_SZ*``LI``)
  `define CH2_TXDRPDO(LI)                      62+(`tSTAT_SZ*``LI``): 47+(`tSTAT_SZ*``LI``)

  `define CH1_TXDRPBUSY(LI)                                           46+(`tSTAT_SZ*``LI``)
  `define CH1_TXDRPRDY(LI)                                            45+(`tSTAT_SZ*``LI``)
  `define CH1_TXDRPDO(LI)                      44+(`tSTAT_SZ*``LI``): 29+(`tSTAT_SZ*``LI``)

  `define CH4_RXGTPOWERGOOD(LI)                                        28+(`tSTAT_SZ*``LI``)
  `define CH4_RXPMARESETDONE(LI)                                       27+(`tSTAT_SZ*``LI``)
  `define CH4_RXRESETDONE(LI)                                          26+(`tSTAT_SZ*``LI``)

  `define CH3_RXGTPOWERGOOD(LI)                                        25+(`tSTAT_SZ*``LI``)
  `define CH3_RXPMARESETDONE(LI)                                       24+(`tSTAT_SZ*``LI``)
  `define CH3_RXRESETDONE(LI)                                          23+(`tSTAT_SZ*``LI``)

  `define CH2_RXGTPOWERGOOD(LI)                                        22+(`tSTAT_SZ*``LI``)
  `define CH2_RXPMARESETDONE(LI)                                       21+(`tSTAT_SZ*``LI``)
  `define CH2_RXRESETDONE(LI)                                          20+(`tSTAT_SZ*``LI``)

  `define CH1_RXGTPOWERGOOD(LI)                                        19+(`tSTAT_SZ*``LI``)
  `define CH1_RXPMARESETDONE(LI)                                       18+(`tSTAT_SZ*``LI``)
  `define CH1_RXRESETDONE(LI)                                          17+(`tSTAT_SZ*``LI``)

  `define CH4_TXGTPOWERGOOD(LI)                                        16+(`tSTAT_SZ*``LI``)
  `define CH4_TXPMARESETDONE(LI)                                       15+(`tSTAT_SZ*``LI``)
  `define CH4_TXRESETDONE(LI)                                          14+(`tSTAT_SZ*``LI``)

  `define CH3_TXGTPOWERGOOD(LI)                                        13+(`tSTAT_SZ*``LI``)
  `define CH3_TXPMARESETDONE(LI)                                       12+(`tSTAT_SZ*``LI``)
  `define CH3_TXRESETDONE(LI)                                          11+(`tSTAT_SZ*``LI``)

  `define CH2_TXGTPOWERGOOD(LI)                                       10+(`tSTAT_SZ*``LI``)
  `define CH2_TXPMARESETDONE(LI)                                       9+(`tSTAT_SZ*``LI``)
  `define CH2_TXRESETDONE(LI)                                          8+(`tSTAT_SZ*``LI``)

  `define CH1_TXGTPOWERGOOD(LI)                                        7+(`tSTAT_SZ*``LI``)
  `define CH1_TXPMARESETDONE(LI)                                       6+(`tSTAT_SZ*``LI``)
  `define CH1_TXRESETDONE(LI)                                          5+(`tSTAT_SZ*``LI``)

  `define QPLL1LOCK(LI)                                                4+(`tSTAT_SZ*``LI``)
  `define QPLL0LOCK(LI)                                                3+(`tSTAT_SZ*``LI``)
  `define RESERVED1(LI)                         2+(`tSTAT_SZ*``LI``):  0+(`tSTAT_SZ*``LI``)

  //CDC Defs
  `define CDC_PULSE      0
  `define CDC_LEVEL      1
  `define CDC_LEVEL_ACK  2
  //XPM_CDC defines
  `define USE_XPM_CDC_PULSE
  `define USE_XPM_CDC_SINGLE
  `define USE_XPM_CDC_ARRAY_SINGLE

  `define XPM_CDC_VERSION 0
  `define XPM_CDC_SIM_ASYNC_RAND 0
  `define XPM_CDC_SIM_ASSERT_CHK 0
  `define XPM_CDC_MTBF_FFS 3

  `define GTID_USRDATA_SEL(ID)      39+``ID``*40:``ID``*40
  `define GTID_TXCTRL0_SEL(ID)      15+``ID``*16:``ID``*16
  `define GTID_TXCTRL1_SEL(ID)      15+``ID``*16:``ID``*16
  `define GTID_TXCTRL2_SEL(ID)       7+``ID``*8 :``ID``*8
  `define GTID_RXCTRL0_SEL(ID)      15+``ID``*16:``ID``*16
  `define GTID_RXCTRL1_SEL(ID)      15+``ID``*16:``ID``*16
  `define GTID_RXCTRL3_SEL(ID)       7+``ID``*8 :``ID``*8

  //Logical Interface
  `define LI_REG_SEL(LI)            31+``LI``*32:``LI``*32

  `define REG0x1C_N_CH_MASK(N_CH)                                (``N_CH``==4?8'hFF<<24:0)+(``N_CH``>=3?8'hFF<<16:0)+(``N_CH``>=2?8'hFF<<8:0)+8'hFF
  `define REG0x24_N_CH_MASK(N_CH)                                (``N_CH``==4?8'hFF<<24:0)+(``N_CH``>=3?8'hFF<<16:0)+(``N_CH``>=2?8'hFF<<8:0)+8'hFF
  `define REG0x30_N_CH_MASK(N_TX_CH,N_RX_CH)                     (``N_TX_CH``==4||``N_RX_CH``==4?8'hFF<<24:0)+(``N_TX_CH``>=3||``N_RX_CH``>=3?8'hFF<<16:0)+(``N_TX_CH``>=2||``N_RX_CH``>=2?8'hFF<<8:0)+8'hFF
  `define REG0x38_N_CH_MASK(N_TX_CH,N_RX_CH)                     (``N_TX_CH``==4||``N_RX_CH``==4?8'h07<<24:0)+(``N_TX_CH``>=3||``N_RX_CH``>=3?8'h07<<16:0)+(``N_TX_CH``>=2||``N_RX_CH``>=2?8'h07<<8:0)+8'h07
  `define REG0x40_N_CH_MASK(N_CH)                                32'hFFFFFFFF
  `define REG0x44_N_CH_MASK(N_CH)                                (``N_CH``>=2?32'hFFFFFFFF:0)
  `define REG0x48_N_CH_MASK(N_CH)                                (``N_CH``>=3?32'hFFFFFFFF:0)
  `define REG0x4C_N_CH_MASK(N_CH)                                (``N_CH``>=4?32'hFFFFFFFF:0)
  `define REG0x70_INIT(POLINV3,POLINV2,POLINV1,POLINV0)          (``POLINV3``==1?1'h1<<25:0)+(``POLINV2``==1?1'h1<<17:0)+(``POLINV1``==1?1'h1<<9:0)+(``POLINV3``==1?1'h1<<1:0)
  `define REG0x70_N_CH_MASK(N_CH)                                (``N_CH``==4?8'hFF<<24:0)+(``N_CH``>=3?8'hFF<<16:0)+(``N_CH``>=2?8'hFF<<8:0)+8'hFF
  `define REG0x74_N_CH_MASK(N_CH)                                (``N_CH``==4?8'hFF<<24:0)+(``N_CH``>=3?8'hFF<<16:0)+(``N_CH``>=2?8'hFF<<8:0)+8'hFF
  `define REG0x7C_N_CH_MASK(N_CH)                                (``N_CH``>=2?16'hFFFF<<16:0)+16'hFFFF
  `define REG0x80_N_CH_MASK(N_CH)                                (``N_CH``==4?16'hFFFF<<16:0)+(``N_CH``>=3?16'hFFFF:0)
  `define REG0x100_INIT(POLINV3,POLINV2,POLINV1,POLINV0)         (``POLINV3``==1?1'h1<<25:0)+(``POLINV2``==1?1'h1<<17:0)+(``POLINV1``==1?1'h1<<9:0)+(``POLINV3``==1?1'h1<<1:0)
  `define REG0x100_N_CH_MASK(N_CH)                               (``N_CH``==4?8'hFF<<24:0)+(``N_CH``>=3?8'hFF<<16:0)+(``N_CH``>=2?8'hFF<<8:0)+8'hFF
  `define REG0x108_N_CH_MASK(N_CH)                               (``N_CH``==4?8'hFF<<24:0)+(``N_CH``>=3?8'hFF<<16:0)+(``N_CH``>=2?8'hFF<<8:0)+8'hFF
  `define REG_TX_PRESENT_MASK(PRTCL)                             (``PRTCL``!=99?32'hFFFFFFFF:0)
  `define REG_RX_PRESENT_MASK(PRTCL)                             (``PRTCL``!=99?32'hFFFFFFFF:0)
  `define REG_DRU_PRESENT_MASK(PRSNT)                            (``PRSNT``!=99?32'hFFFFFFFF:0)

`endif

