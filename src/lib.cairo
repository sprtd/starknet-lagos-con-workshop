pub mod counter;
pub mod errors;
pub mod addition;
pub mod counter_v2;
pub mod counter_v3;
pub mod counter_v4;

#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    fn increase_balance(ref self: TContractState, amount: felt252);
    fn get_balance(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod HelloStarknet {
    #[storage]
    struct Storage {
        balance: felt252,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}

#[test]
#[ignore]
#[cfg(test)]
mod tests {
    use starknet::ContractAddress;

    use snforge_std::{declare, ContractClassTrait};

    use hands_on::IHelloStarknetSafeDispatcher;
    use hands_on::IHelloStarknetSafeDispatcherTrait;
    use hands_on::IHelloStarknetDispatcher;
    use hands_on::IHelloStarknetDispatcherTrait;

    fn deploy_contract(name: ByteArray) -> ContractAddress {
        let contract = declare(name).unwrap();
        let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
        contract_address
    }

    #[test]
    fn test_increase_balance() {
        let contract_address = deploy_contract("HelloStarknet");

        let dispatcher = IHelloStarknetDispatcher { contract_address };

        let balance_before = dispatcher.get_balance();
        assert(balance_before == 0, 'Invalid balance');

        dispatcher.increase_balance(42);

        let balance_after = dispatcher.get_balance();
        assert(balance_after == 42, 'Invalid balance');
    }

    #[test]
    #[feature("safe_dispatcher")]
    fn test_cannot_increase_balance_with_zero_value() {
        let contract_address = deploy_contract("HelloStarknet");

        let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

        let balance_before = safe_dispatcher.get_balance().unwrap();
        assert(balance_before == 0, 'Invalid balance');

        match safe_dispatcher.increase_balance(0) {
            Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
            Result::Err(panic_data) => {
                assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
            }
        };
    }
}
