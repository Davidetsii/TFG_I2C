library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity i2c_master_tb is
--  Port ( );
end i2c_master_tb;

architecture Behavioral of i2c_master_tb is

    constant CLK_PERIOD : time := 10 ns;
    
    signal clk, reset_n, start, done, r_w, sda, scl : std_logic;
    signal address : std_logic_vector(6 downto 0);
    signal data_in : std_logic_vector(7 downto 0);
    signal data_out : std_logic_vector(15 downto 0);

begin

    dut : entity work.i2c_master
    generic map (
            C_FREQ_SYS   => 100000000,
            C_FREQ_I2C   => 100000                       
    )
    port map ( 
            clk      => clk,
            reset_n  => reset_n,
            start    => start,
            address  => address,
            data_in  => data_in,
            done     => done,
            sda      => sda,
            scl      => scl,
            data_out => data_out,
            r_w      => r_w
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
        -- I2C initial values 
        scl <= 'H';
        sda <= 'H';
    
        -- IP initial values
        reset_n <= '0';
        start <= '0';
        r_w <= '1';
        address <= (others => '0');
        data_in <= (others => '0');
        wait for 5*CLK_PERIOD;
        
        reset_n <= '1';
        wait for 500*CLK_PERIOD;
        
        -- Rest of the simulation
        
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        if r_w = '0' then
            wait for 9250*CLK_PERIOD + CLK_PERIOD/2;           
            sda <= '0'; -- ACK / NACK SLAVE ADDRESS
            wait for 1000*CLK_PERIOD;
            sda <= 'H'; 
            wait for 10000*CLK_PERIOD;
            sda <= '0'; -- ACK / NACK SLAVE
            wait for 1000*CLK_PERIOD;
            sda <= 'H';
        else
            wait for 9250*CLK_PERIOD + CLK_PERIOD/2;           
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

        end if;
        wait;
    
    end process;

end Behavioral;
