`timescale 1ns / 1ps

module TopModule(
    // Clock
    input logic CLK100MHZ,
    
    // Ethernet PHY
    // https://en.wikipedia.org/wiki/Media-independent_interface
    output logic eth_ref_clk,   // Reference Clock X1
    output logic eth_rstn,      // Reset Phy
    output logic eth_mdc,       // management interface
    inout logic eth_mdio,
    
    input logic eth_rx_clk,     // Rx clock
    input logic eth_rx_dv,      // Rx data valid
    input logic[3:0] eth_rxd,   // Rx data bus
    
    input logic eth_rxerr,     // Receive error
    input logic eth_col,        // Ethernet collision
    input logic eth_crs,        // Ethernet carrier sense
    
    input logic eth_tx_clk,     // Tx clock
    output logic eth_tx_en,     // Transmit enable
    output logic[3:0] eth_txd,  // Tx data bus
    
    // LEDs
    output logic[3:0] led,
    output logic led0_g,        // UDP connected
    output logic led1_r,        // UDP tx valid
    output logic led1_g,        // UDP rx valid
    output logic led1_b,        // UDP tx ready
    output logic led2_g         // IP OK
);
    localparam int IP_ADDR = 'hC0A82A45; // 192.168.42.69
    localparam int PORT = 'hE001;        // 57345
    
    
    logic IP_Ok;
    logic UDP0_Connected;
    logic UDP0_OutIsEmpty;
    
    logic[7:0] UDP0_TxData;
    logic UDP0_TxReady;
    logic UDP0_TxValid;
    logic UDP0_TxLast;
    
    logic[7:0] UDP0_RxData;
    logic UDP0_RxReady;
    logic UDP0_RxValid;
    logic UDP0_RxLast;
    
    logic[3:0] package_count = 0;
    logic is_header = 0;
    logic[7:0] last_header = 0; // first byte of each udp package
    
    
    // UDP loopback
    assign UDP0_TxData = UDP0_RxData + 8'h20; // upper to lower
    assign UDP0_TxValid = UDP0_RxValid;
    assign UDP0_RxReady = UDP0_TxReady;
    assign UDP0_TxLast = UDP0_RxLast;
    
    // Debug LEDs
    assign led0_g = UDP0_Connected;
    assign led1_r = UDP0_TxValid;
    assign led1_g = UDP0_RxValid;
    assign led1_b = UDP0_RxReady;
    assign led2_g = IP_Ok;
    assign led = package_count;
    
    always @(posedge UDP0_RxLast) begin
        package_count <= package_count + 1;
    end
    

    // Instantiate FC1001_MII Ethernet to UPD core
    // https://www.fpga-cores.com/cores/fc1001_mii/
    FC1001_MII eth (
        .Clk(CLK100MHZ),
        .Reset(0),
        
        // IP settings
        .UseDHCP(0),
        .IP_Addr(IP_ADDR),
        .IP_Ok(IP_Ok),
        
        // UDP setup
        .UDP0_Reset(0),
        .UDP0_Service('h0112),
        .UDP0_ServerPort(PORT),
        
        // Status
        .UDP0_Connected(UDP0_Connected),
        .UDP0_OutIsEmpty(UDP0_OutIsEmpty),
        
        // AXI4 Stream Slave
        .UDP0_TxData(UDP0_TxData),
        .UDP0_TxReady(UDP0_TxReady),
        .UDP0_TxValid(UDP0_TxValid),
        .UDP0_TxLast(UDP0_TxLast),
        
        // AXI4 Stream Master  
        .UDP0_RxData(UDP0_RxData),
        .UDP0_RxReady(UDP0_RxReady),
        .UDP0_RxValid(UDP0_RxValid),
        .UDP0_RxLast(UDP0_RxLast),
        
        // MII interface to Ethernet PHY
        .MII_REF_CLK_25M(eth_ref_clk),
        .MII_RST_N(eth_rstn),
        .MII_MDC(eth_mdc),
        .MII_MDIO(eth_mdio),
        .MII_COL(eth_col),
        .MII_CRS(eth_crs),
        .MII_RX_CLK(eth_rx_clk),
        .MII_CRS_DV(eth_rx_dv),
        .MII_RXD(eth_rxd),
        .MII_RXERR(eth_rxerr),
        .MII_TX_CLK(eth_tx_clk),
        .MII_TXEN(eth_tx_en),
        .MII_TXD(eth_txd)
    );
endmodule
