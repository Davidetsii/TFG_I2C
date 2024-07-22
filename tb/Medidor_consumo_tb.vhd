library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Medidor_consumo_tb is
end Medidor_consumo_tb;

architecture Behavioral of Medidor_consumo_tb is
    constant C_FREQ_SYS   : integer := 100000000;
    constant C_FREQ_I2C   : integer := 100000;
    constant C_DATA_WIDTH : integer := 32;
    constant C_ADDR_WIDTH : integer := 32;
    constant C_MEM_DEPTH  : integer := 4096;
    constant C_MEM_MODE   : string  := "LOW_LATENCY";

    signal clk       : std_logic := '0';
    signal reset     : std_logic := '0';
    signal start     : std_logic := '0';
    signal stop      : std_logic := '0';
    signal r_w       : std_logic := '0';
    signal address   : std_logic_vector(6 downto 0) := (others => '0');
    signal data_in   : std_logic_vector(7 downto 0) := (others => '0');
    signal addr_a    : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal data_a_out: std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal addr_b    : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal data_b    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    signal data_b_out: std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal we_b      : std_logic := '0';
    signal en_b      : std_logic := '0';
    signal cont      : std_logic;
    signal sda       : std_logic := 'Z';
    signal scl       : std_logic := 'Z';
    signal data_slave: std_logic_vector(7 downto 0);

    -- Clock generation
    constant clk_period : time := 10 ns;
begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: entity work.Medidor_consumo
        generic map (
            freq          => 10000,
            C_FREQ_SYS    => C_FREQ_SYS,
            C_FREQ_I2C    => C_FREQ_I2C,
            C_DATA_WIDTH  => C_DATA_WIDTH,
            C_ADDR_WIDTH  => C_ADDR_WIDTH,
            C_MEM_DEPTH   => C_MEM_DEPTH,
            C_MEM_MODE    => C_MEM_MODE
        )
        port map (
            clk        => clk,
            reset      => reset,
            start      => start,
            stop       => stop,
            r_w        => r_w,
            address    => address,
            data_in    => data_in,
            addr_a     => addr_a,
            data_a_out => data_a_out,
            addr_b     => addr_b,
            data_b     => data_b,
            data_b_out => data_b_out,
            we_b       => we_b,
            en_b       => en_b,
            cont       => cont,
            sda        => sda,
            scl        => scl
        );

    -- Clock process definitions
    clk_process : process
    begin
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset the system
        reset <= '1';
        scl <= 'H';
        sda <= 'H';  
        data_slave <= x"aa";     
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- Start signal
        r_w <= '1';
        address <= "0000010";
        data_in <= "11001100";
        addr_a <= x"00000002";        
        start <= '1';
        wait for 20 ns;
        start <= '0';

        if r_w = '0' then
            wait for 19251*CLK_PERIOD + CLK_PERIOD/2;           
            sda <= '0'; -- ACK / NACK SLAVE ADDRESS
            wait for 1000*CLK_PERIOD;
            sda <= 'H'; 
            wait for 10000*CLK_PERIOD;
            sda <= '0'; -- ACK / NACK SLAVE
            wait for 1000*CLK_PERIOD;
            sda <= 'H';
        else
            for k in 0 to 10 loop
                if k = 0 then
                    wait for 19251*CLK_PERIOD + CLK_PERIOD/2; 
                else
                    wait for 33005*CLK_PERIOD;
                end if;          
                sda <= '0'; -- ACK / NACK SLAVE ADDRESS
                wait for 1000*CLK_PERIOD;
                sda <= 'H'; 
                wait for 10000*CLK_PERIOD;
                sda <= '0'; -- ACK / NACK SLAVE
                wait for 1000*CLK_PERIOD;            
                sda <= 'H';  
                wait for 13500*CLK_PERIOD;
                sda <= '0'; -- ACK / NACK SLAVE ADDRESS
                wait for 1000*CLK_PERIOD;
                sda <= 'H';    
                wait for 2000*CLK_PERIOD;
                for i in 0 to 7 loop
                    sda <= data_slave(7 - i);
                    wait for 1000*CLK_PERIOD;
                end loop;
                data_slave <= data_slave(6 downto 0)&(not data_slave(7));
                sda <= 'H';
            end loop;
        end if;
        
        wait for 30000*CLK_PERIOD;

        -- Stop signal
        stop <= '1';
        wait for 20 ns;
        stop <= '0';
        wait for 20 ns;

        -- End of simulation
        wait;
    end process;
end Behavioral;
