library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bram_dualport_tb is
end bram_dualport_tb;

architecture behavioral of bram_dualport_tb is

    -- Component declaration
    component bram_dualport
        generic (
            C_DATA_WIDTH : integer := 32;
            C_ADDR_WIDTH : integer := 32;
            C_MEM_DEPTH  : integer := 4096;
            C_MEM_MODE   : string := "LOW_LATENCY"
        );
        port (
            -- Port A --
            clk_a  : in  std_logic;
            rst_a  : in  std_logic;
            en_a   : in  std_logic;
            we_a   : in  std_logic;
            addr_a : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            din_a  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_a : out std_logic_vector(C_DATA_WIDTH-1 downto 0);

            -- Port B --
            clk_b  : in  std_logic;
            rst_b  : in  std_logic;
            en_b   : in  std_logic;
            we_b   : in  std_logic;
            addr_b : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            din_b  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_b : out std_logic_vector(C_DATA_WIDTH-1 downto 0)
        );
    end component;

    -- Signals for Port A
    signal clk_a  : std_logic := '0';
    signal rst_a  : std_logic := '0';
    signal en_a   : std_logic := '0';
    signal we_a   : std_logic := '0';
    signal addr_a : std_logic_vector(31 downto 0) := (others => '0');
    signal din_a  : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_a : std_logic_vector(31 downto 0);

    -- Signals for Port B
    signal clk_b  : std_logic := '0';
    signal rst_b  : std_logic := '0';
    signal en_b   : std_logic := '0';
    signal we_b   : std_logic := '0';
    signal addr_b : std_logic_vector(31 downto 0) := (others => '0');
    signal din_b  : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_b : std_logic_vector(31 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: bram_dualport
        generic map (
            C_DATA_WIDTH => 32,
            C_ADDR_WIDTH => 32,
            C_MEM_DEPTH  => 4096,
            C_MEM_MODE   => "LOW_LATENCY" -- Change to "HIGH_PERFORMANCE" to test that mode
        )
        port map (
            -- Port A
            clk_a  => clk_a,
            rst_a  => rst_a,
            en_a   => en_a,
            we_a   => we_a,
            addr_a => addr_a,
            din_a  => din_a,
            dout_a => dout_a,

            -- Port B
            clk_b  => clk_b,
            rst_b  => rst_b,
            en_b   => en_b,
            we_b   => we_b,
            addr_b => addr_b,
            din_b  => din_b,
            dout_b => dout_b
        );

    -- Clock generation for Port A
    clk_a_process : process
    begin
        clk_a <= '0';
        wait for clk_period / 2;
        clk_a <= '1';
        wait for clk_period / 2;
    end process;

    -- Clock generation for Port B
    clk_b_process : process
    begin
        clk_b <= '0';
        wait for clk_period / 2;
        clk_b <= '1';
        wait for clk_period / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset both ports
        rst_a <= '1';
        rst_b <= '1';
        wait for clk_period * 2;
        rst_a <= '0';
        rst_b <= '0';
        wait for clk_period * 2;

        -- Write to Port A
        en_a <= '1';
        we_a <= '1';
        addr_a <= std_logic_vector(to_unsigned(28, 32));
        din_a <= x"00001010";
        --wait for clk_period;

        -- Write to Port B
        en_b <= '1';
        we_b <= '0';
        addr_b <= std_logic_vector(to_unsigned(28, 32));
        din_b <= x"00000003";
        wait for clk_period;
        
        addr_a <= std_logic_vector(to_unsigned(29, 32));
        din_a <= x"00002020";
        wait for clk_period;

        -- Read from Port A
        we_a <= '0';
        addr_a <= std_logic_vector(to_unsigned(28, 32));
        wait for clk_period;
        
        addr_a <= std_logic_vector(to_unsigned(29, 32));
        wait for clk_period;



        addr_b <= std_logic_vector(to_unsigned(29, 32));
        din_b <= x"00000004";
        wait for clk_period;

        -- Read from Port B
        we_b <= '0';
        addr_b <= std_logic_vector(to_unsigned(2, 32));
        wait for clk_period;

        addr_b <= std_logic_vector(to_unsigned(3, 32));
        wait for clk_period;

        -- Additional tests can be added here
        
        -- Finish simulation
        wait;
    end process;

end behavioral;

