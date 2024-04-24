
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_I2C_master is
        generic (
                    C_FREQ_SYS  : integer := 125000000;    -- 125 MHz
                    C_FREQ_SCL  : integer := 125000        -- 125 KHz en SCL                          
        );
end tb_I2C_master;

architecture Behavioral of tb_I2C_master is

    constant CLK_PERIOD : time := (1000000000/C_FREQ_SYS)* 1ns; -- 125 MHz
    constant SCL_PERIOD : time := (1000000/C_FREQ_SCL)* 1us; -- 125 MHz 88
    signal clk, reset, START, DONE, SDA, SCL, ack_s, overflow   : std_logic;
    signal R_W          : std_logic := '0';
    signal DATA_SLAVE   : std_logic_vector(7 downto 0) := x"35";
    signal DATA_READ    : std_logic_vector(7 downto 0);
    signal DATA_IN      : std_logic_vector(7 downto 0) := x"5d";
    signal ADDRESS      : std_logic_vector(6 downto 0) := "1010101";
    signal BYTES_W      : std_logic_vector(1 downto 0) := "11";
    signal BYTES_R      : std_logic_vector(1 downto 0) := "00";
    signal div          : std_logic_vector(1 downto 0);
    

begin

    I2C_master : entity work.I2C_master
        generic map(
                    C_FREQ_SYS  => C_FREQ_SYS,
                    C_FREQ_SCL  => C_FREQ_SCL
        )
        port map(
                    clk     => clk,
                    reset   => reset,
                    START   => START,     
                    R_W     => R_W, 
                    ADDRESS     => ADDRESS,
                    DATA_IN     => DATA_IN,                 
                    DONE    => DONE,
                    SDA     => SDA,
                    SCL     => SCL,
                    DATA_READ  => DATA_READ,
                    BYTES_W     => BYTES_W,
                    BYTES_R     => BYTES_R,
                    overflow    => overflow,
                    div         => div,
                    ack_s       => ack_s                    
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
        reset <= '1';
        START <= '0';
        SDA <= 'Z';
        wait for SCL_PERIOD/8;
            
        reset <= '0';
            
        if BYTES_R = "00" then
            wait for SCL_PERIOD/8;
            START <= '1';
            wait for CLK_PERIOD + CLK_PERIOD/4;
            START <= '0';
            for k in 0 to to_integer(unsigned(BYTES_W)) - 1 loop
                wait until div = "00" and ack_s = '1' and overflow = '1';
                DATA_IN <= DATA_IN(0)&DATA_IN(7 downto 1);            
            end loop;            
            wait;
        else
            wait for SCL_PERIOD/8;
            START <= '1';
            wait for CLK_PERIOD + CLK_PERIOD/4;
            START <= '0'; 
            for k in 0 to to_integer(unsigned(BYTES_W)) - 1 loop
                wait until div = "00" and ack_s = '1' and overflow = '1';
                DATA_IN <= DATA_IN(0)&DATA_IN(7 downto 1);            
            end loop;
            wait for 11*SCL_PERIOD*2;
            
            wait for 3*SCL_PERIOD +3*SCL_PERIOD/2 + 999*CLK_PERIOD;
            
            for k in 0 to to_integer(unsigned(BYTES_R)) - 1 loop
                for i in 0 to 6 loop
                    SDA <= DATA_SLAVE(7 - i);
                    wait for SCL_PERIOD;
                end loop;
                SDA <= DATA_SLAVE(0);
                wait for SCL_PERIOD;
                SDA <= 'Z';   
                wait for 2*SCL_PERIOD;
                DATA_SLAVE <= DATA_SLAVE(6 downto 0)&'1';
                wait for SCL_PERIOD;
            end loop;                                                           
            wait;
        end if;
    end process;        

end Behavioral;
