library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity i2c_master_tb is
--  Port ( );
end i2c_master_tb;

architecture Behavioral of i2c_master_tb is

    constant CLK_PERIOD : time := 10 ns;
    
    signal clk, reset_n, start, done, r_w, sda_in, sda_out, sda_en, scl_in, scl_out, scl_en : std_logic;
    signal address : std_logic_vector(6 downto 0);
    signal data_in : std_logic_vector(7 downto 0);
    signal data_out : std_logic_vector(15 downto 0);
    
    signal scl, sda : std_logic;

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
            sda_in   => sda_in,
            sda_out  => sda_out,
            sda_en   => sda_en,
            scl_in   => scl_in,
            scl_out  => scl_out,
            scl_en   => scl_en,
            data_out => data_out,
            r_w      => r_w
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
        address <= "0101010";
        data_in <= "11001100";
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
