
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_I2C_master is
        generic (
                    C_FREQ_SYS  : integer := 100000000;    -- 100 MHz
                    C_FREQ_I2C  : integer := 100000        -- 100 KHz en SCL                          
        );
end tb_I2C_master;

architecture Behavioral of tb_I2C_master is

    constant CLK_PERIOD : time := (1000000000/C_FREQ_SYS)* 1ns; -- 100 MHz
    constant SCL_PERIOD : time := (1000000/C_FREQ_I2C)* 1us; -- 100 KHz 
    signal clk, reset_n, start, done, sda, scl   : std_logic;
    signal r_w  : std_logic := '0';
    signal DATA_SLAVE   : std_logic_vector(7 downto 0) := x"35";
    signal data_out    : std_logic_vector(15 downto 0);
    signal data_in      : std_logic_vector(7 downto 0) := x"5d";
    signal address      : std_logic_vector(6 downto 0) := "1010101";

    

begin

    I2C_master : entity work.i2c_master
        generic map(
                    C_FREQ_SYS  => C_FREQ_SYS,
                    C_FREQ_I2C  => C_FREQ_I2C
        )
        port map(
                    clk     => clk,
                    reset_n => reset_n,
                    start   => start,     
                    address     => address,
                    data_in     => data_in,                 
                    done    => done,
                    sda     => sda,
                    scl     => scl,
                    data_out  => data_out,
                    r_w     => r_w             
        );
        
    clk_stimuli : process
        begin
            clk <= '1';
            wait for CLK_PERIOD/2;
            clk <= '0';
            wait for CLK_PERIOD/2;
        end process;
    
    I2C_stimuli : process
    begin
        reset_n <= '0';
        start <= '0';
        sda <= 'Z';
        wait for SCL_PERIOD/8;
            
        reset_n <= '1';
            
        if r_w = '0' then
            wait for SCL_PERIOD/8;
            start <= '1';
            wait for CLK_PERIOD + CLK_PERIOD/4;
            start <= '0';
            wait for 9*SCL_PERIOD + SCL_PERIOD/2;
            for k in 0 to 0 loop
                data_in <= data_in(0)&data_in(7 downto 1);
                wait for 11*SCL_PERIOD;            
            end loop;            
            wait;
        else
            wait for SCL_PERIOD/8;
            START <= '1';
            wait for CLK_PERIOD + CLK_PERIOD/4;
            START <= '0'; 
            wait for 9*SCL_PERIOD + SCL_PERIOD/2;
            for k in 0 to 0 loop
                data_in <= data_in(0)&data_in(7 downto 1);         
                wait for 11*SCL_PERIOD; 
            end loop;
            wait for 10*SCL_PERIOD + 3*SCL_PERIOD/4;
            
            wait for 4*SCL_PERIOD +3*SCL_PERIOD/2 + 999*CLK_PERIOD;
            
            for k in 0 to 1 loop
                for i in 0 to 6 loop
                    sda <= DATA_SLAVE(7 - i);
                    wait for SCL_PERIOD;
                end loop;
                sda <= DATA_SLAVE(0);
                wait for SCL_PERIOD;
                sda <= 'Z';   
                wait for 2*SCL_PERIOD;
                DATA_SLAVE <= DATA_SLAVE(6 downto 0)&'1';
                wait for SCL_PERIOD;
            end loop;                                                           
            wait;
        end if;
    end process;        

end Behavioral;
