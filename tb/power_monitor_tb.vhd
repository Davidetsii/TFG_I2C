library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity power_monitor_tb is
    generic (
        C_SLV_ADDR      : std_logic_vector(6 downto 0) :="0101000";
        C_CMD           : std_logic_vector(7 downto 0) := x"10";    
        C_FREQ_SYS    : integer := 100000000;    -- 100 MHz
        C_FREQ_I2C    : integer := 1000000; --100000;       -- 100 KHz en SCL
        C_DATA_WIDTH  : integer := 16;
        C_MEM_DEPTH   : integer := 10;        -- 4096 Number of memory positions
        C_MEM_DEPTH_LG2 : integer := 12         -- Log2 of C_MEM_DEPTH
    );
end power_monitor_tb;

architecture Behavioral of power_monitor_tb is

    signal clk_i     : std_logic;
    signal rst_ni    : std_logic;
    signal start_i   : std_logic;
    signal stop_i    : std_logic;
    signal read_en_i : std_logic;
    signal done_o    : std_logic;
    signal data_o: std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal sample_cnt_o     : std_logic_vector(C_MEM_DEPTH_LG2-1 downto 0);
    signal sda       : std_logic := 'Z';
    signal scl       : std_logic := 'Z';
    signal data_slave: unsigned(7 downto 0);
    signal timer_cnt_i : std_logic_vector(31 downto 0);

    -- Clock generation
    constant clk_period : time := 10 ns;
begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: entity work.power_monitor
        generic map (
            C_SLV_ADDR    => C_SLV_ADDR,
            C_CMD         => C_CMD,
            C_FREQ_SYS    => C_FREQ_SYS,
            C_FREQ_I2C    => C_FREQ_I2C,
            C_DATA_WIDTH  => C_DATA_WIDTH,
            C_MEM_DEPTH   => C_MEM_DEPTH,
            C_MEM_DEPTH_LG2 => C_MEM_DEPTH_LG2
        )
        port map (
            clk_i      => clk_i,
            rst_ni     => rst_ni,
            start_i    => start_i,
            stop_i     => stop_i,
            read_en_i  => read_en_i,
            data_o     => data_o,
            sample_cnt_o => sample_cnt_o,
            timer_cnt_i=> timer_cnt_i,
            done_o     => done_o,
            sda        => sda,
            scl        => scl
        );

    -- Clock process definitions
    clk_process : process
    begin
            clk_i <= '0';
            wait for clk_period / 2;
            clk_i <= '1';
            wait for clk_period / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset the system
        --read <= '0';
        read_en_i <= '0';       
        --write_en_i <= '1'; 
        rst_ni <= '0';
        stop_i <= '0';
        start_i <= '0';
        timer_cnt_i <= x"00002000";
        scl <= 'H';
        sda <= 'H';  
        data_slave <= x"00";     
        wait for 5*clk_period;
        rst_ni <= '1';
        wait for 10*clk_period;

        -- Start signal
        --read <= '0';    
        start_i <= '1';
        wait for clk_period;
        start_i <= '0';
        wait for clk_period;

        for k in 0 to 9 loop --4095
            if k = 0 then
                wait for 925*CLK_PERIOD + CLK_PERIOD/2; 
            else
                wait for 4542*CLK_PERIOD;
            end if;          
            sda <= '0'; -- ACK / NACK SLAVE ADDRESS
            wait for 100*CLK_PERIOD;
            sda <= 'H'; 
            wait for 1000*CLK_PERIOD;
            sda <= '0'; -- ACK / NACK SLAVE
            wait for 100*CLK_PERIOD;            
            sda <= 'H';  
            wait for 1350*CLK_PERIOD;
            sda <= '0'; -- ACK / NACK SLAVE ADDRESS
            wait for 100*CLK_PERIOD;
            sda <= 'H';    
            wait for 200*CLK_PERIOD;
            for i in 0 to 7 loop
                sda <= data_slave(7 - i);
                wait for 100*CLK_PERIOD;
            end loop;
            data_slave <= data_slave + 1;
            sda <= 'H';
        end loop;
        
        wait for 30000*CLK_PERIOD;
        

        -- Stop signal
--        stop_i <= '1';
--        wait for 20 ns;
--        stop_i <= '0';
--        wait for 20 ns;
        --read <= '1';
        --write_en_i <= '0';
        read_en_i <= '1';


        -- End of simulation
        wait;
    end process;
end Behavioral;
