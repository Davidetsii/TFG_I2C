library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity power_monitor is
    generic (
        C_SLV_ADDR      : std_logic_vector(6 downto 0) :="0101000";
        C_CMD           : std_logic_vector(7 downto 0) := x"00";    
        C_FREQ_SYS    : integer := 100000000;    -- 100 MHz
        C_FREQ_I2C    : integer := 100000;       -- 100 KHz en SCL
        C_DATA_WIDTH  : integer := 32;
        C_ADDR_WIDTH  : integer := 32;
        C_MEM_DEPTH   : integer := 4096;        -- Number of memory positions
        C_MEM_DEPTH_LG2 : integer := 12;         -- Log2 of C_MEM_DEPTH
        C_MEM_MODE    : string  := "LOW_LATENCY" -- Memory performance configuration mode
    );
    Port ( 
        clk_i     : in  std_logic;
        rst_ni    : in  std_logic;
        start_i   : in  std_logic;
        stop_i    : in  std_logic;
        read_en_i : in std_logic;
        read      : in std_logic;
        write_en_i: in std_logic;
        r_w       : in std_logic;
        address   : in  std_logic_vector(6 downto 0);
        data_in   : in  std_logic_vector(7 downto 0);
        data_a_out: out std_logic_vector(C_DATA_WIDTH-1 downto 0); -- No se utiliza
        --data_b    : in  std_logic_vector(C_DATA_WIDTH-1 downto 0); -- No se utiliza
        data_b_out: out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        timer_cnt_i:in  std_logic_vector(31 downto 0);
        done_o    : out std_logic;
        sda       : inout std_logic;
        scl       : inout std_logic
    );
end power_monitor;

architecture Behavioral of power_monitor is

    signal on_off, reset_i2c, done, rst : std_logic;
    signal sda_in, sda_en, sda_out : std_logic;
    signal scl_in, scl_en, scl_out : std_logic;
    signal data_out         : std_logic_vector(15 downto 0);
    signal reset_n          : std_logic;
    signal data_a           : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal sample_cnt_o     : std_logic_vector(C_MEM_DEPTH_LG2-1 downto 0);
    signal en_a, we_a, en_b, we_b : std_logic;
    signal addr_a, addr_b   : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    signal data_b_aux           : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    

begin



    -- Instancia de FSM_temp
    FSM_INST : entity work.FSM_temp
        generic map(
                C_MEM_DEPTH     => C_MEM_DEPTH,
                C_MEM_DEPTH_LG2 => C_MEM_DEPTH_LG2
        )
        port map(
            clk     => clk_i,
            reset   => rst,
            start   => start_i,
            stop    => stop_i,
            on_off  => on_off,
            reset_i2c => reset_i2c,
            sample_cnt_o => sample_cnt_o,
            done_o  => done_o,
            read_en_i => read,
            timer_cnt_i => timer_cnt_i
        );

    -- Instancia de i2c_master
    I2C_INST : entity work.i2c_master
        generic map(
            C_FREQ_SYS => C_FREQ_SYS,
            C_FREQ_I2C => C_FREQ_I2C
        )
        port map(
            clk       => clk_i,
            reset_n   => reset_n,
            start     => on_off,
            address   => C_SLV_ADDR,
            data_in   => C_CMD,
            done      => done,
            sda_in    => sda_in,
            sda_en    => sda_en,
            sda_out   => sda_out,
            scl_in    => scl_in,
            scl_en    => scl_en,
            scl_out   => scl_out,
            data_out  => data_out,
            r_w       => r_w
        );

    -- Instancia de bram_dualport
    BRAM_INST : entity work.bram_dualport
        generic map(
            C_DATA_WIDTH => C_DATA_WIDTH,
            C_ADDR_WIDTH => C_ADDR_WIDTH,
            C_MEM_DEPTH  => C_MEM_DEPTH,
            C_MEM_MODE   => C_MEM_MODE
        )
        port map(
        
            -- Puerto A - Escritura
            clk_a  => clk_i,
            rst_a  => rst,
            en_a   => write_en_i,
            we_a   => we_a,
            addr_a => addr_a,
            din_a  => data_a,
            dout_a => data_a_out, 
            
            -- Puerto A - Lectura
            clk_b  => clk_i,
            rst_b  => rst,
            en_b   => read_en_i,
            we_b   => we_b,
            addr_b => addr_b,
            din_b  => data_b_aux,
            dout_b => data_b_out 
        );

    IOBUF_SCL_inst : IOBUF
    generic map (
      DRIVE => 12,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
    port map (
      O => scl_in,     -- Buffer output
      IO => scl,   -- Buffer inout port (connect directly to top-level port)
      I => scl_out,     -- Buffer input
      T => scl_en      -- 3-state enable input, high=input, low=output 
    );
    
    IOBUF_SDA_inst : IOBUF
    generic map (
      DRIVE => 12,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
    port map (
      O => sda_in,     -- Buffer output
      IO => sda,   -- Buffer inout port (connect directly to top-level port)
      I => sda_out,     -- Buffer input
      T => sda_en      -- 3-state enable input, high=input, low=output 
    );    
    
    reset_n <= (not reset_i2c) and rst_ni;
    data_a  <= x"0000" & data_out;
    rst     <= not rst_ni;
    --en_a    <= '0' when rst_ni = '0' else '1';
    --en_b    <= '0' when rst_ni = '0' else '1';
    we_a    <= '1';
    we_b    <= '0';
    addr_a  <= x"00000" & sample_cnt_o;
    addr_b  <= x"00000" & sample_cnt_o;
    data_b_aux <= (others => '0');

end Behavioral;


