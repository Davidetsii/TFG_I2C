library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity Medidor_consumo is
    generic (
        freq          : integer := 10000;
        C_FREQ_SYS    : integer := 100000000;    -- 100 MHz
        C_FREQ_I2C    : integer := 100000;       -- 100 KHz en SCL
        C_DATA_WIDTH  : integer := 32;
        C_ADDR_WIDTH  : integer := 32;
        C_MEM_DEPTH   : integer := 4096;
        C_MEM_MODE    : string  := "LOW_LATENCY" -- Memory performance configuration mode
    );
    Port ( 
        clk       : in  std_logic;
        reset     : in  std_logic;
        start     : in  std_logic;
        stop      : in  std_logic;
        r_w       : in  std_logic;
        address   : in  std_logic_vector(6 downto 0);
        data_in   : in  std_logic_vector(7 downto 0);
        addr_a    : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        data_a_out: out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        addr_b    : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0); -- No se utiliza
        data_b    : in  std_logic_vector(C_DATA_WIDTH-1 downto 0); -- No se utiliza
        data_b_out: out std_logic_vector(C_DATA_WIDTH-1 downto 0); -- No se utiliza
        we_b      : in  std_logic; -- No se utiliza
        en_b      : in  std_logic; -- No se utiliza
        cont      : out std_logic;
        sda       : inout std_logic;
        scl       : inout std_logic
    );
end Medidor_consumo;

architecture Behavioral of Medidor_consumo is

    signal done, on_off, reset_i2c : std_logic;
    signal sda_in, sda_en, sda_out : std_logic;
    signal scl_in, scl_en, scl_out : std_logic;
    signal data_out         : std_logic_vector(15 downto 0);
    signal reset_n          : std_logic;
    signal we_a             : std_logic;
    signal data_a           : std_logic_vector(C_DATA_WIDTH-1 downto 0);

begin

    -- Instancia de FSM_temp
    FSM_INST : entity work.FSM_temp
        generic map(
            freq => freq
        )
        port map(
            clk     => clk,
            reset   => reset,
            start   => start,
            stop    => stop,
            done    => done,
            on_off  => on_off,
            cont    => cont,
            reset_i2c => reset_i2c
        );

    -- Instancia de i2c_master
    I2C_INST : entity work.i2c_master
        generic map(
            C_FREQ_SYS => C_FREQ_SYS,
            C_FREQ_I2C => C_FREQ_I2C
        )
        port map(
            clk       => clk,
            reset_n   => reset_n,
            start     => on_off,
            address   => address,
            data_in   => data_in,
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
            clk_a  => clk,
            rst_a  => reset,
            en_a   => done,
            we_a   => we_a,
            addr_a => addr_a,
            din_a  => data_a,
            dout_a => data_a_out, 

            clk_b  => clk,
            rst_b  => reset,
            en_b   => en_b,
            we_b   => we_b,
            addr_b => addr_b,
            din_b  => data_b,
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
    
    reset_n <= (not reset_i2c) and (not reset);
    data_a  <= x"0000" & data_out;
    we_a    <= done and (not scl_in);
    

end Behavioral;


