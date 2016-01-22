//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Fri Jan 22 11:29:19 2016
// Version: v11.6 11.6.0.34
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// top
module top(
    // Inputs
    ADCdin,
    CLKA,
    eepromMISO,
    rst,
    rxd,
    watchdogenSwitch,
    // Outputs
    ADCcs,
    ADCmode,
    ADCrng,
    ADCsclk,
    ADCsel,
    aliveLED,
    busyLEDAD7782,
    busyLEDADT7301,
    busyLEDEEPROM,
    busyLEDMstr,
    eepromCS,
    eepromMOSI,
    eepromORG,
    eepromSCLK,
    txd,
    watchdogEnLED
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  ADCdin;
input  CLKA;
input  eepromMISO;
input  rst;
input  rxd;
input  watchdogenSwitch;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output ADCcs;
output ADCmode;
output ADCrng;
output ADCsclk;
output ADCsel;
output aliveLED;
output busyLEDAD7782;
output busyLEDADT7301;
output busyLEDEEPROM;
output busyLEDMstr;
output eepromCS;
output eepromMOSI;
output eepromORG;
output eepromSCLK;
output txd;
output watchdogEnLED;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   ADCcs_net_0;
wire   ADCdin;
wire   ADCmode_net_0;
wire   ADCrng_net_0;
wire   ADCsclk_net_0;
wire   ADCsel_net_0;
wire   aliveLED_net_0;
wire   busyLEDAD7782_net_0;
wire   busyLEDADT7301_net_0;
wire   busyLEDEEPROM_net_0;
wire   busyLEDMstr_net_0;
wire   CLKA;
wire   eepromCS_net_0;
wire   eepromMISO;
wire   eepromMOSI_net_0;
wire   eepromORG_net_0;
wire   eepromSCLK_net_0;
wire   rxd;
wire   sCLK_0_GLA;
wire   txd_net_0;
wire   watchdogEnLED_net_0;
wire   watchdogenSwitch;
wire   ADCsclk_net_1;
wire   ADCcs_net_1;
wire   ADCmode_net_1;
wire   ADCsel_net_1;
wire   ADCrng_net_1;
wire   eepromORG_net_1;
wire   eepromMOSI_net_1;
wire   eepromSCLK_net_1;
wire   eepromCS_net_1;
wire   busyLEDADT7301_net_1;
wire   busyLEDAD7782_net_1;
wire   busyLEDEEPROM_net_1;
wire   busyLEDMstr_net_1;
wire   aliveLED_net_1;
wire   watchdogEnLED_net_1;
wire   txd_net_1;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire   VCC_net;
//--------------------------------------------------------------------
// Inverted Nets
//--------------------------------------------------------------------
wire   rst;
wire   rst_IN_POST_INV0_0;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign VCC_net = 1'b1;
//--------------------------------------------------------------------
// Inversions
//--------------------------------------------------------------------
assign rst_IN_POST_INV0_0 = ~ rst;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign ADCsclk_net_1        = ADCsclk_net_0;
assign ADCsclk              = ADCsclk_net_1;
assign ADCcs_net_1          = ADCcs_net_0;
assign ADCcs                = ADCcs_net_1;
assign ADCmode_net_1        = ADCmode_net_0;
assign ADCmode              = ADCmode_net_1;
assign ADCsel_net_1         = ADCsel_net_0;
assign ADCsel               = ADCsel_net_1;
assign ADCrng_net_1         = ADCrng_net_0;
assign ADCrng               = ADCrng_net_1;
assign eepromORG_net_1      = eepromORG_net_0;
assign eepromORG            = eepromORG_net_1;
assign eepromMOSI_net_1     = eepromMOSI_net_0;
assign eepromMOSI           = eepromMOSI_net_1;
assign eepromSCLK_net_1     = eepromSCLK_net_0;
assign eepromSCLK           = eepromSCLK_net_1;
assign eepromCS_net_1       = eepromCS_net_0;
assign eepromCS             = eepromCS_net_1;
assign busyLEDADT7301_net_1 = busyLEDADT7301_net_0;
assign busyLEDADT7301       = busyLEDADT7301_net_1;
assign busyLEDAD7782_net_1  = busyLEDAD7782_net_0;
assign busyLEDAD7782        = busyLEDAD7782_net_1;
assign busyLEDEEPROM_net_1  = busyLEDEEPROM_net_0;
assign busyLEDEEPROM        = busyLEDEEPROM_net_1;
assign busyLEDMstr_net_1    = busyLEDMstr_net_0;
assign busyLEDMstr          = busyLEDMstr_net_1;
assign aliveLED_net_1       = aliveLED_net_0;
assign aliveLED             = aliveLED_net_1;
assign watchdogEnLED_net_1  = watchdogEnLED_net_0;
assign watchdogEnLED        = watchdogEnLED_net_1;
assign txd_net_1            = txd_net_0;
assign txd                  = txd_net_1;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------CONNECTOR
CONNECTOR CONNECTOR_0(
        // Inputs
        .rst              ( rst_IN_POST_INV0_0 ),
        .clk              ( sCLK_0_GLA ),
        .rxd              ( rxd ),
        .watchdogenSwitch ( watchdogenSwitch ),
        .eepromMISO       ( eepromMISO ),
        .ADCdin           ( ADCdin ),
        // Outputs
        .txd              ( txd_net_0 ),
        .watchdogEnLED    ( watchdogEnLED_net_0 ),
        .aliveLED         ( aliveLED_net_0 ),
        .busyLEDMstr      ( busyLEDMstr_net_0 ),
        .busyLEDEEPROM    ( busyLEDEEPROM_net_0 ),
        .busyLEDAD7782    ( busyLEDAD7782_net_0 ),
        .busyLEDADT7301   ( busyLEDADT7301_net_0 ),
        .eepromCS         ( eepromCS_net_0 ),
        .eepromSCLK       ( eepromSCLK_net_0 ),
        .eepromMOSI       ( eepromMOSI_net_0 ),
        .eepromORG        ( eepromORG_net_0 ),
        .ADCrng           ( ADCrng_net_0 ),
        .ADCsel           ( ADCsel_net_0 ),
        .ADCmode          ( ADCmode_net_0 ),
        .ADCcs            ( ADCcs_net_0 ),
        .ADCsclk          ( ADCsclk_net_0 ) 
        );

//--------sCLK
sCLK sCLK_0(
        // Inputs
        .POWERDOWN ( VCC_net ),
        .CLKA      ( CLKA ),
        // Outputs
        .LOCK      (  ),
        .GLA       ( sCLK_0_GLA ) 
        );


endmodule
