library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity power_monitor_tb is
    generic (
        C_SLV_ADDR      : std_logic_vector(6 downto 0) :="0101000";
        C_CMD           : std_logic_vector(7 downto 0) := x"00";    
        C_FREQ_SYS    : integer := 100000000;    -- 100 MHz
        C_FREQ_I2C    : integer := 1000000; --100000;       -- 100 KHz en SCL
        C_DATA_WIDTH  : integer := 32;
        C_ADDR_WIDTH  : integer := 32;
        C_MEM_DEPTH   : integer := 100;        -- 4096 Number of memory positions
        C_MEM_DEPTH_LG2 : integer := 12;         -- Log2 of C_MEM_DEPTH
        C_MEM_MODE    : string  := "LOW_LATENCY" -- Memory performance configuration mode
    );
end power_monitor_tb;

architecture Behavioral of power_monitor_tb is

    signal clk_i     : std_logic;
    signal r_w       : std_logic;
    signal rst_ni    : std_logic;
    signal start_i   : std_logic;
    signal stop_i    : std_logic;
    signal read_en_i : std_logic;
    signal write_en_i: std_logic;
    signal done_o    : std_logic;
    signal read      : std_logic;
    signal address   : std_logic_vector(6 downto 0);
    signal data_in   : std_logic_vector(7 downto 0);
    signal data_a_out: std_logic_vector(C_DATA_WIDTH-1 downto 0);
    --signal data_b    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal data_b_out: std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal sda       : std_logic := 'Z';
    signal scl       : std_logic := 'Z';
    signal data_slave: std_logic_vector(7 downto 0);
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
            C_ADDR_WIDTH  => C_ADDR_WIDTH,
            C_MEM_DEPTH   => C_MEM_DEPTH,
            C_MEM_DEPTH_LG2 => C_MEM_DEPTH_LG2,
            C_MEM_MODE    => C_MEM_MODE
        )
        port map (
            clk_i      => clk_i,
            rst_ni     => rst_ni,
            start_i    => start_i,
            stop_i     => stop_i,
            read       => read,
            read_en_i  => read_en_i,
            write_en_i => write_en_i,
            address    => address,
            data_in    => data_in,
            r_w        => r_w,
            data_a_out => data_a_out,
          --  data_b     => data_b,
            data_b_out => data_b_out,
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
        read <= '0';
        read_en_i <= '0';       
        write_en_i <= '1'; 
        rst_ni <= '0';
        stop_i <= '0';
        start_i <= '0';
        r_w     <= '1';
        data_in <= (others => '0');
        timer_cnt_i <= x"00002000";
        scl <= 'H';
        sda <= 'H';  
        data_slave <= x"aa";     
        wait for 20 ns;
        rst_ni <= '1';
        wait for 20 ns;

        -- Start signal
        address <= "0101000"; 
        read <= '0';    
        start_i <= '1';
        wait for 20 ns;
        start_i <= '0';

        if read = '0' then
            for k in 0 to 99 loop --4095
                if k = 0 then
                    wait for 9118*CLK_PERIOD + CLK_PERIOD/2; 
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
                data_slave <= data_slave(6 downto 0)&(not data_slave(7));
                sda <= 'H';
            end loop;
        end if;
        
        wait for 30000*CLK_PERIOD;
        

        -- Stop signal
        stop_i <= '1';
        wait for 20 ns;
        stop_i <= '0';
        wait for 20 ns;
        read <= '1';
        write_en_i <= '0';
        read_en_i <= '1';
        start_i <= '1';
        wait for 20 ns;
        start_i <= '0';

        -- End of simulation
        wait;
    end process;
end Behavioral;
