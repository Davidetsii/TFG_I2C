
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity FSM_temp_tb is
    generic (
                freq    : integer := 100
    );
end FSM_temp_tb;

architecture Behavioral of FSM_temp_tb is
    
    constant CLK_PERIOD : time := 10 ns;
    signal clk, reset, start, stop, done, on_off, cont, reset_i2c   : std_logic;

begin

    dut : entity work.FSM_temp
    generic map (
                    freq    =>  freq
    )
    port map(
                    clk     =>  clk,
                    reset   =>  reset,
                    start   =>  start,
                    stop    =>  stop,
                    done    =>  done,
                    on_off  =>  on_off,
                    cont    =>  cont,
                    reset_i2c => reset_i2c
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
        
        done <= '0';
        stop <= '0';
        start <= '0';
        reset <= '0';
        wait for 5*CLK_PERIOD;
        
        reset <= '1';
        wait for 500*CLK_PERIOD;
        reset <= '0';
        wait for 100*CLK_PERIOD;
        start <= '1';
        wait for 200*CLK_PERIOD;
        start <= '0';
        wait for 100*CLK_PERIOD;
        done  <= '1';
        wait for 200*CLK_PERIOD;
        done  <= '0';
        wait for 100*CLK_PERIOD;
        done  <= '1';
        wait for 200*CLK_PERIOD;
        done  <= '0';
        wait for 100*CLK_PERIOD;
        done  <= '1';
        wait for 200*CLK_PERIOD;
        done  <= '0';
        wait for 100*CLK_PERIOD;                
        stop <= '1';
        wait for 200*CLK_PERIOD;
        stop <= '0';
        wait;
        
    end process;      

end Behavioral;
