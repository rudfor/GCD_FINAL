-- -----------------------------------------------------------------------------
--
--  Title      :  Testbench for the GCD module
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--             :
--  Purpose    :  A testbench for the gcp module providing a simulated clock
--             :  and a sequence of test data. This module is written using
--             :  imperative VHDL and is only used for testing (can not be
--             :  synthesised)
--             :
--  Revision   : 02203 fall 2019 v.6.0
--
-- -----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- The testbench entity is an completely isolated entity with no input/output
entity gcd_tb is
end gcd_tb;

-- Architecture of the testbench. Instantiates the gcd entity and provides it
-- with test data. The result is then compared to the actual result for verification.
architecture behaviour of gcd_tb is

	-- Period of the clock 
	constant CLOCK : time := 20 ns;

	component gcd
		port (clk : in std_logic;             -- The clock signal.
			reset : in  std_logic;              -- Reset the module.
			req   : in  std_logic;              -- Start computation.
			AB    : in  unsigned(15 downto 0);  -- The two operands.
			ack   : out std_logic;              -- Computation is complete.
            s_blue  : out std_logic;             -- last input received / computation is complete.
            s_green : out std_logic;            -- last input received / computation is complete.
            s_red   : out std_logic;            -- last input received / computation is complete.
            C     : out unsigned(15 downto 0)); -- The result.
	end component;

	-- Internal signals
	signal clk, reset : std_logic;
	signal req, ack   : std_logic;
	signal s_blue, s_green, s_red   : std_logic;
	signal AB, C      : unsigned(15 downto 0);

begin

		-- Instantiate gcd module and wire it up to internal signals used for testing
		g : gcd port map(
			clk   => clk,
			reset => reset,
			req   => req,
			AB    => AB,
			ack   => ack,
			s_blue  => s_blue,
			s_green  => s_green,
			s_red  => s_red,
			C     => C
		);

	-- Clock generation (simulation use only)
	process
	begin
		clk <= '1'; wait for CLOCK/2;
		clk <= '0'; wait for CLOCK/2;
	end process;

	-- Process to provide test input to the entity in the testbench
	process

		constant N_OPS : natural := 5;

		type t_ops is array (0 to N_OPS-1) of natural;
		-- Change numbers here if you what to run different tests
		variable a_ops     : t_ops := (91, 32768, 49, 29232, 25);
		variable b_ops     : t_ops := (63, 272, 98, 488, 5);
		variable c_results : t_ops := (7, 16, 49, 8, 5);
	begin

		-- Reset entity for some clock cycles
		reset <= '1';
		wait for CLOCK*4;
		reset <= '0';
		wait for CLOCK;

		for i in 0 to N_OPS-1 loop
			-- Supply first operand
			req <= '1';
			AB  <= to_unsigned(a_ops(i), AB'length);

			-- Wait for ack high
			while (ack /= '1') loop
				wait for CLOCK;
			end loop;

			req <= '0';

			-- Wait for ack low
			while (ack /= '0') loop
				wait for CLOCK;
			end loop;

			-- Supply second operand
			req <= '1';
			AB  <= to_unsigned(b_ops(i), AB'length);

			-- Wait for ack high
			while (ack /= '1') loop
				wait for CLOCK;
			end loop;

			-- Test the result of the computation
			assert C = to_unsigned(c_results(i),C'length) report "Wrong result!" severity failure;

			req <= '0';

			-- Wait for ack low
			while (ack /= '0') loop
				wait for CLOCK;
			end loop;

		end loop;

		wait for CLOCK;
		report "Tests succeeded!" severity note;
		std.env.stop(0);

	end process;

end behaviour;
