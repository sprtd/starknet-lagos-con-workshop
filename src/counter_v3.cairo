use starknet::ContractAddress;

#[starknet::interface]
pub trait ICounterV3<TContractState> {
    fn increase_count(ref self: TContractState, amount: u32);
    fn get_count(self: @TContractState) -> u32;
    fn get_owner(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod CounterV3 {
    use starknet::{get_caller_address, ContractAddress};
    use hands_on::errors::Errors;

    #[storage]
    struct Storage {
        count: u32,
        owner: ContractAddress
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredCount: StoredCount
    }

    #[derive(Drop, starknet::Event)]
    struct StoredCount {
        new_count: u32,
        caller: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState, _owner: ContractAddress) {
        self.owner.write(_owner);
    }

    #[abi(embed_v0)]
    impl ICounterImpl of super::ICounterV3<ContractState> {
        fn increase_count(ref self: ContractState, amount: u32) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), Errors::NOT_OWNER);
            assert(amount != 0, hands_on::errors::Errors::ZERO_AMOUNT);
            let current_count: u32 = self.count.read();
            let result = hands_on::addition::add_num(current_count, amount);
            self.count.write(result);
            self.emit(StoredCount { new_count: result, caller: caller });
        }

        fn get_count(self: @ContractState) -> u32 {
            self.count.read()
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }
}

