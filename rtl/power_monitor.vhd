library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity power_monitor is
    generic (
        C_SLV_ADDR      : std_logic_vector(6 downto 0) :="0101000";
        C_CMD           : std_logic_vector(7 downto 0) := x"10";    
        C_FREQ_SYS    : integer := 100000000;    -- 100 MHz
        C_FREQ_I2C    : integer := 100000;       -- 100 KHz en SCL
        C_DATA_WIDTH  : integer := 16;
        C_MEM_DEPTH   : integer := 4096;        -- Number of memory positions
        C_MEM_DEPTH_LG2 : integer := 12         -- Log2 of C_MEM_DEPTH
    );
    Port ( 
        clk_i     : in  std_logic;
        rst_ni    : in  std_logic;
        start_i   : in  std_logic;
        stop_i    : in  std_logic;
        read_en_i : in std_logic;
        --read      : in std_logic;
        --write_en_i: in std_logic;
--        r_w       : in std_logic;
--        address   : in  std_logic_vector(6 downto 0);
--        data_in   : in  std_logic_vector(7 downto 0);
--        data_a_out: out std_logic_vector(C_DATA_WIDTH-1 downto 0); -- No se utiliza
        --data_b    : in  std_logic_vector(C_DATA_WIDTH-1 downto 0); -- No se utiliza
        data_o: out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        timer_cnt_i:in  std_logic_vector(31 downto 0);
        done_o    : out std_logic;
        sample_cnt_o     : out std_logic_vector(C_MEM_DEPTH_LG2-1 downto 0);
        sda       : inout std_logic;
        scl       : inout std_logic
    );
end power_monitor;

architecture Behavioral of power_monitor is

    signal start_i2c, reset_i2c, done, done_edge, done_reg, rst : std_logic;
    signal sda_in, sda_en, sda_out : std_logic;
    signal scl_in, scl_en, scl_out : std_logic;
    signal data_out         : std_logic_vector(15 downto 0);
    signal reset_n          : std_logic;
    signal data_a           : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal sample_cnt     : std_logic_vector(C_MEM_DEPTH_LG2-1 downto 0);
    signal en_a, we_a, en_b, we_b : std_logic;
--    signal addr : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    signal data_b_aux           : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    

begin

    REG_FLANCO: process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            done_reg <= '0';
        elsif clk_i'event and clk_i = '1' then  
            done_reg <= done;
        end if;
    end process;
    
    done_edge <= done and (not done_reg);

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
            done_edge    => done_edge,
            start_i2c  => start_i2c,
            reset_i2c => reset_i2c,
            sample_cnt_o => sample_cnt,
            done_o  => done_o,
            read_en_i => read_en_i,
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
            start     => start_i2c,
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
            r_w       => '1'
        );

    -- Instancia de bram_dualport
    BRAM_INST : entity work.bram_dualport
        generic map(
            C_DATA_WIDTH => C_DATA_WIDTH,
            C_ADDR_WIDTH => C_MEM_DEPTH_LG2,
            C_MEM_DEPTH  => C_MEM_DEPTH
        )
        port map(
        
            -- Puerto A - Escritura
            clk_a  => clk_i,
            rst_a  => rst,
            en_a   => done_edge,
            we_a   => done_edge,
            addr_a => sample_cnt,
            din_a  => data_a,
            dout_a => open, 
            
            -- Puerto B - Lectura
            clk_b  => clk_i,
            rst_b  => rst,
            en_b   => read_en_i,
            we_b   => '0',
            addr_b => sample_cnt,
            din_b  => (others => '0'),
            dout_b => data_o 
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
    data_a  <= data_out;
    rst     <= not rst_ni;
    en_a    <= not read_en_i;
    --en_b    <= '0' when rst_ni = '0' else '1';
--    we_a    <= '1';
--    we_b    <= '0';
--    addr  <=  sample_cnt;
    data_b_aux <= (others => '0');

    sample_cnt_o <= sample_cnt;

end Behavioral;


