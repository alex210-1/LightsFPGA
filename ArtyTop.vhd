

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;


entity Top is
    Port ( 
        CLK100MHZ       : in STD_LOGIC;
    
        -- Ethernet MII  DP83848J
        eth_ref_clk     : out std_logic;                    -- Reference Clock X1
            
        eth_mdc         : out std_logic;
        eth_mdio        : inout std_logic;
        eth_rstn        : out std_logic;                    -- Reset Phy
    
        eth_rx_clk      : in  std_logic;                     -- Rx Clock
        eth_rx_dv       : in  std_logic;                     -- Rx Data Valid
        eth_rxd         : in  std_logic_vector(3 downto 0);  -- RxData
            
        eth_rxerr       : in  std_logic;                     -- Receive Error
        eth_col         : in  std_logic;                     -- Ethernet Collision
        eth_crs         : in  std_logic;                     -- Ethernet Carrier Sense
                    
        eth_tx_clk      : in  std_logic;                     -- Tx Clock
        eth_tx_en       : out std_logic;                     -- Transmit Enable
        eth_txd         : out std_logic_vector(3 downto 0);  -- Transmit Data
        
        -- SPI Flash Mem
        qspi_cs         : out std_logic;        
        qspi_dq         : inout std_logic_vector(3 downto 0)   -- dg(0) is MOSI, dq(1) MISO
        
        --RGB LEDs  
        --led0_b          : out std_logic;
        --led0_g          : out std_logic;
        --led0_r          : out std_logic;
        --led1_b          : out std_logic;
        --led1_g          : out std_logic;
        --led1_r          : out std_logic;
        --led2_b          : out std_logic;
        --led2_g          : out std_logic;
        --led2_r          : out std_logic;
        --led3_b          : out std_logic;
        --led3_g          : out std_logic;
        --led3_r          : out std_logic

        --Chip kit
        --ck_io           : out std_logic_vector(5 downto 0);

        -- USB UART
        --uart_rxd_out    : out std_logic; 
        --uart_txd_in     : in  std_logic
            
    );
end Top;

architecture IMPL of Top is
        
    component FC1002_MII is    
    port (
        Clk             : in  std_logic;    -- 100MHz
        Reset           : in  std_logic;    -- Active high

        ----------------------------------------------------------------
        -- System Setup
        ----------------------------------------------------------------
        UseDHCP         : in  std_logic;
        IP_Addr         : in  std_logic_vector(8*4-1 downto 0); -- If UseDHCP = '0'
        
        ----------------------------------------------------------------
        -- System Status
        ----------------------------------------------------------------
        IP_Ok           : out std_logic;
        
        ----------------------------------------------------------------
        -- SPI Flash Boot Control
        ----------------------------------------------------------------
        SPI_CSn         : out std_logic;
        SPI_SCK         : out std_logic;
        SPI_MOSI        : out std_logic;
        SPI_MISO        : in  std_logic;
        
        ----------------------------------------------------------------
        -- TCP0 Basic Server With Service Exposer
        ----------------------------------------------------------------
        -- Setup 
        TCP0_Service    : in  std_logic_vector(15 downto 0);        
        TCP0_ServerPort : in  std_logic_vector(15 downto 0);
        
        -- Status
        TCP0_Connected  : out std_logic;
        TCP0_AllAcked   : out std_logic;
        TCP0_nTxFree    : out unsigned(15 downto 0);
        TCP0_nRxData    : out unsigned(15 downto 0);
        
        -- AXI4 Stream Slave
        TCP0_TxData     : in  std_logic_vector(7 downto 0);
        TCP0_TxValid    : in  std_logic;
        TCP0_TxReady    : out std_logic;
        
        -- AXI4 Stream Master        
        TCP0_RxData     : out std_logic_vector(7 downto 0);
        TCP0_RxValid    : out std_logic;
        TCP0_RxReady    : in  std_logic;
        
        ----------------------------------------------------------------
        -- Logic Analyzer
        ----------------------------------------------------------------
        LA0_TrigIn      : in  std_logic;
        LA0_Clk         : in  std_logic;
        LA0_TrigOut     : out std_logic;
        LA0_Signals     : in  std_logic_vector(31 downto 0);
        LA0_SampleEn    : in  std_logic;
        
        ----------------------------
        -- MII Interface
        ----------------------------
        MII_REF_CLK_25M : out std_logic;    -- 25MHz 
        MII_RST_N       : out std_logic;     
        MII_COL         : in  std_logic;    -- Ethernet Collision
        MII_CRS         : in  std_logic;    -- Ethernet Carrier Sense        
        MII_RX_CLK      : in  std_logic;     -- 25MHz or 2.5MHz
        MII_CRS_DV      : in  std_logic; 
        MII_RXD         : in  std_logic_vector(3 downto 0); 
        MII_RXERR       : in  std_logic;     
        MII_TX_CLK      : in  std_logic;     -- 25MHz or 2.5MHz
        MII_TXEN        : out std_logic; 
        MII_TXD         : out std_logic_vector(3 downto 0)
                
    );
    end component FC_1002_MII;
    
    
    signal IP_Ok            : std_logic := '0';
     
    signal TCP0_Connected   : std_logic;
    signal TCP0_AllAcked    : std_logic;
            
    signal TCP0_TxData      : std_logic_vector(7 downto 0);  
    signal TCP0_TxValid     : std_logic;
    signal TCP0_TxReady     : std_logic;
        
    signal TCP0_RxData      : std_logic_vector(7 downto 0);
    signal TCP0_RxValid     : std_logic;
    signal TCP0_RxReady     : std_logic;
        
    signal LA0_TrigIn       : std_logic;
    signal LA0_Clk          : std_logic;
    signal LA0_TrigOut      : std_logic;
    signal LA0_Signals      : std_logic_vector(31 downto 0);
    signal LA0_SampleEn     : std_logic;
    
   
begin


    -- Loopback TCP 
    TCP0_TxData     <= TCP0_RxData;
    TCP0_TxValid    <= TCP0_RxValid;
    TCP0_RxReady    <= TCP0_TxReady;
    
    i_FC_1002_MII : FC1002_MII
    port map (
        Clk             => CLK100MHZ,       -- 100 MHz
        Reset           => '0',             -- Active high

        ----------------------------------------------------------------
        -- System Setup
        ----------------------------------------------------------------
        UseDHCP         => '1',
        IP_Addr         => (others=>'0'),
        
        ----------------------------------------------------------------
        -- System Status
        ----------------------------------------------------------------
        IP_Ok           => IP_Ok,           -- '1' when DHCP has solved IP
        
        ----------------------------------------------------------------
        -- SPI Flash Boot Control
        ----------------------------------------------------------------
        SPI_CSn         => qspi_cs,
        SPI_SCK         => open, --??qspi_sck,
        SPI_MOSI        => qspi_dq(0),
        SPI_MISO        => qspi_dq(1),
        
        ----------------------------------------------------------------
        -- TCP0 Basic Server With Service Exposer
        ----------------------------------------------------------------
        -- Setup 
        TCP0_Service    => x"0112",
        TCP0_ServerPort => x"E001",
        
        -- Status
        TCP0_Connected  => TCP0_Connected,
        TCP0_AllAcked   => TCP0_AllAcked, 
        TCP0_nTxFree    => open,
        TCP0_nRxData    => open,
        
        -- AXI4 Stream Slave
        TCP0_TxData     => TCP0_TxData,  
        TCP0_TxValid    => TCP0_TxValid, 
        TCP0_TxReady    => TCP0_TxReady, 
        
        -- AXI4 Stream Master        
        TCP0_RxData     => TCP0_RxData, 
        TCP0_RxValid    => TCP0_RxValid,
        TCP0_RxReady    => TCP0_RxReady,
        
        ----------------------------------------------------------------
        -- Logic Analyzer
        ----------------------------------------------------------------
        LA0_TrigIn      => LA0_TrigIn,   
        LA0_Clk         => LA0_Clk,      
        LA0_TrigOut     => LA0_TrigOut,  
        LA0_Signals     => LA0_Signals,  
        LA0_SampleEn    => LA0_SampleEn, 
        
        ----------------------------
        -- MII Interface
        ----------------------------
        MII_REF_CLK_25M => eth_ref_clk,
        MII_RST_N       => eth_rstn,
        MII_COL         => eth_col,
        MII_CRS         => eth_crs, 
        MII_RX_CLK      => eth_rx_clk,
        MII_CRS_DV      => eth_rx_dv,
        MII_RXD         => eth_rxd,
        MII_RXERR       => eth_rxerr,   
        MII_TX_CLK      => eth_tx_clk,
        MII_TXEN        => eth_tx_en,
        MII_TXD         => eth_txd         
    );
    
    LA0_Clk <= CLK100MHZ;
    
    -- Create some data for the Logic Analyzer
    ILATestP : process ( CLK100MHZ ) is
        variable f0         : unsigned(7 downto 0) := to_unsigned(2,8);
        variable f1         : unsigned(7 downto 0) := to_unsigned(2,8);
        variable v          : unsigned(15 downto 0) := to_unsigned(0,16);
        variable vf         : unsigned(15 downto 0) := to_unsigned(0,16);
        variable highbit    : std_logic := '0';
        variable up         : boolean := TRUE;
        variable up1        : boolean := TRUE;
        variable wait_ms    : integer range 0 to 100 := 0;
        variable clk_cnt    : integer range 0 to 100_000 := 0;
    begin
    
        if rising_edge( CLK100MHZ ) then
            
            LA0_SampleEn    <= '1';
            LA0_TrigIn      <= '0';
            LA0_Signals(27 downto 0) <= std_logic_vector( f0 & vf(15 downto 6) & v(15 downto 6) );
                      
            if wait_ms > 0 then
                if clk_cnt = 100_000 then
                    clk_cnt:=0;
                    wait_ms := wait_ms - 1;
                else
                    clk_cnt := clk_cnt + 1;
                end if;
            else
                
                v := v + (f0&"000") + f1;
                
                if v(v'high) = '0' and highbit = '1' then
                    if up then
                        if f0 = 20 then
                            up := FALSE;
                            wait_ms := 100;
                        else
                            f0 := f0 + 1;
                        end if;
                    else
                        if f0 = 2 then
                            up := TRUE;
                            LA0_TrigIn <= '1';
                            
                            f1 := f1 + 1;
                            
                        else
                            f0 := f0 - 1;
                        end if;
                    end if;
                end if;
                
            end if;
                    
            highbit := v(v'high);
            
        end if;
    
    end process;
    
end IMPL;
