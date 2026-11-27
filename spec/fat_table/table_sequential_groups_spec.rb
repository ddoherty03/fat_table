# frozen_string_literal: true

module FatTable
  RSpec.describe Table do
    describe 'group context during sequential transformations' do
      let(:tab) do
        table = Table.from_aoh((1..6).map { |id| { id: id } })
        table.mark_boundary(0)
        table.mark_boundary(2)
        table
      end

      it 'preserves group context in select expressions and both hooks' do
        result = tab.select(
          :id,
          group_number: '@group',
          before_group: '@before_group',
          previous_group: '@previous_group',
          ivars: { previous_group: 0 },
          before_hook: '@before_group = @group',
          after_hook: '@previous_group = @group',
        )

        expect(result[:group_number]).to eq([1, 2, 2, 3, 3, 3])
        expect(result[:before_group]).to eq([1, 2, 2, 3, 3, 3])
        expect(result[:previous_group]).to eq([0, 1, 2, 2, 3, 3])
        expect(result.boundaries).to eq([0, 2, 5])
        expect(tab.boundaries).to eq([0, 2, 5])
      end

      it 'uses original row and group numbers even when whole groups are filtered out' do
        result = tab.where('@group == 3 && @row.odd?')

        expect(result[:id]).to eq([5])
        expect(result.boundaries).to eq([0])
        expect(tab.boundaries).to eq([0, 2, 5])
      end

      it 'handles an implicit group with no explicit boundaries' do
        tab.degroup!

        expect(tab.select(group_number: '@group')[:group_number]).to eq([1, 1, 1, 1, 1, 1])
        expect(tab.where('@group == 1')[:id]).to eq([1, 2, 3, 4, 5, 6])
      end

      it 'handles an explicitly marked final boundary' do
        tab.mark_boundary

        expect(tab.select(group_number: '@group')[:group_number]).to eq([1, 2, 2, 3, 3, 3])
        expect(tab.where('@group == 3')[:id]).to eq([4, 5, 6])
      end

      it 'does not evaluate expressions for empty tables' do
        empty = Table.new(:id)

        expect(empty.select(value: 'raise "must not evaluate"')).to be_empty
        expect(empty.where('raise "must not evaluate"')).to be_empty
      end
    end
  end
end
