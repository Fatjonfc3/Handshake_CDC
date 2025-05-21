use IEEE.std_logic.all;
use IEEE.numeric_std.all;


entity handshake is 
port (
	clk1 , clk2 : in std_logic ;
	rst1 , rst2 : in std_logic ;
	data_domain_1 : in std_logic_logic_vector ( 7 downto 0);
	data_domain_2 : out std_logic_vector ( 7 downto 0 )
)
end entity handshake;


architecture rtl of handshake is

signal valid_domain_1 , ready_domain_2 : std_logic;
signal valid_1_domain2 , valid_2_domain2 ,valid_3_domain2 : std_logic;
signal ready_1_domain_1 , ready_2_domain_1 , ready_3_domain_1 : std_logic;

signal send_data , receive_data : std_logic; --internal signals , because im not implementing a fsm

signal data_reg_domain_1 : std_logic_vector ( 7 downto 0 );
signal data_reg_domain_2 : std_logic_vector ( 7 downto 0 );
type array --to send bursts
begin

domain_1_sender: process ( clk1 )
begin
	if rising_edge ( clk1) then
		ready_1_domain_1 <= ready_domain_2;
		ready_2_domain_1 <= ready_1_domain_1;
		ready_3_domain_1 <= ready_2_domain_1;
		if ready_3_domain_1 = '1' and ready_2_domain_1 ='0' then
			send_data = '0' ; -- we got the toggle that it received the data also put the valid to 0 so the contract is that 						after we detect that it has an edge triggered we sample the data and then we do not 								trust anymore the input
			valid_domain_1 <= '0';
		end if;
		if send_data = '0' then
			data_reg_domain_1 <= data_domain_1 ; --supposing no metastability issue supposing it's synchronous
			send_data <= '1';
			valid_domain_1 <= '1';
		end if;
		if send_data = '1' then
			valid_domain_1 <= '1'; -- hold the high  or also do other stuff without changing the data_reg_domain_1 
						--if the ready has fallen we don't care, I mean we still wait till it toggles 0 to 1
						
		end if;
	end if;
end process domain_1;

domain_2_receiver : process ( clk2)
begin
	if rising_edge ( clk2 )
		valid_1_domain_2 <= valid_domain_1;
		valid_2_domain_2 <= valid_1_domain_2;
		valid_3_domain_2 <= valid_2_domain_2;
		if valid_3_domain_2 = '1' and valid_2_domain_2 = '0' then
			receive_data <= '1';
			ready_1_domain_1 <= '0';
			-- we ould also capture here the data and then go to a state that we don't capture new data just process it
		end if;
	
		if receive_data = '1' then
			data_reg_domain_2 <= data_reg_domain_1 ;
			receive_data <= '0';
			ready_1_domain_1 <= '1';
		end if;
		if receive_data = '0' then
			-- do other stuff with the data you sample don't sample new data wait till you get a new edge trigger of valid
			-- we don't suffer of pulse lost bcs we hold value
			-- we don't suffer of thinking the input is still valid only if its high 
			-- we make a contract between receiver and sender that after an edge trigger we sample the data and after 				capturing the data no other data is thought to be valid until we get a new one
		end if;




end process domain_2_receiver;
