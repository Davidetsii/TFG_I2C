
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity FSM_temp_tb is
    generic(
                C_MEM_DEPTH     : integer := 4096;      -- Number of memory positions
                C_MEM_DEPTH_LG2 : integer := 12         -- Log2 of C_MEM_DEPTH
    );
end FSM_temp_tb;

architecture Behavioral of FSM_temp_tb is
    
    constant CLK_PERIOD : time := 10 ns;
    signal clk, reset, start, stop, on_off, reset_i2c, read_en_i, done_o  : std_logic;
    signal timer_cnt_i  : std_logic_vector(31 downto 0);
    signal sample_cnt_o  : std_logic_vector(C_MEM_DEPTH_LG2-1 downto 0);
    

begin

    dut : entity work.FSM_temp
    generic map(
                    C_MEM_DEPTH => C_MEM_DEPTH,
                    C_MEM_DEPTH_LG2 => C_MEM_DEPTH_LG2
    )
    port map(
                    clk     =>  clk,
                    reset   =>  reset,
                    start   =>  start,
                    stop    =>  stop,
                    on_off  =>  on_off,
                    reset_i2c => reset_i2c,
                    sample_cnt_o => sample_cnt_o,
                    done_o      => done_o,
                    read_en_i   => read_en_i,
                    timer_cnt_i => timer_cnt_i
    );          
    
    clk_stimuli : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;     
    
    dut_stimuli : process
    begin   
        stop <= '0';
        start <= '0';
        reset <= '0';
        read_en_i <= '0';
        --timer_cnt_i <= x"00080000"; -- aproximadamente 5 ms
        timer_cnt_i <= x"00000080";
        wait for 5*CLK_PERIOD;
        
        reset <= '1';
        wait for 500*CLK_PERIOD;
        reset <= '0';
        wait for 100*CLK_PERIOD;
        start <= '1';
        wait for 200*CLK_PERIOD;
        start <= '0';

        wait for 3 ms;
        stop <= '1';
        wait for 100*CLK_PERIOD;
        stop <= '0';
        wait;
        
    end process;      

end Behavioral;
