# frozen_string_literal: true

module FatTable
  RSpec.describe Table do
    # Compare complete results to the original evaluator path, including its
    # column suppression and ordering, without duplicating those rules here.
    def expect_reference_join(left, right, *expressions, join_type: :inner)
      actual = left.join(right, *expressions, join_type: join_type)
      allow(left).to receive(:build_join_index).and_return(nil)
      expected = left.join(right, *expressions, join_type: join_type)
      expect(actual.headers).to eq(expected.headers)
      expect(actual.rows).to eq(expected.rows)
      expect(actual.boundaries).to eq(expected.boundaries)
      allow(left).to receive(:build_join_index).and_call_original
      actual
    end

    describe 'indexed equality joins' do
      let(:equality_expressions) { [[], [:id], [:id_a, :id_b], [:id_b, :id_a]] }
      let(:left) do
        described_class.from_aoh([
          { id: 2, label: 'second' },
          { id: nil, label: 'nil' },
          { id: 1, label: 'first' },
          { id: 2, label: 'duplicate' },
          { id: 4, label: 'unmatched' },
        ])
      end
      let(:right) do
        described_class.from_aoh([
          { id: 2, detail: 'first match' },
          { id: 3, detail: 'unmatched' },
          { id: nil, detail: 'nil match' },
          { id: 2, detail: 'second match' },
          { id: 1, detail: 'last match' },
        ])
      end

      [:inner, :left, :right, :full].each do |type|
        it "preserves duplicates, nil matches, and row order for #{type} joins" do
          left.explicit_boundaries = [1]
          equality_expressions.each do |expressions|
            expect_reference_join(left, right, *expressions, join_type: type)
          end
        end

        it "handles empty inputs for #{type} joins" do
          expect_reference_join(left.empty_dup, right, join_type: type)
          expect_reference_join(left, right.empty_dup, join_type: type)
          expect_reference_join(left.empty_dup, right.empty_dup, join_type: type)
        end
      end

      it 'matches composite keys including booleans and strings' do
        a = described_class.from_aoh([
          { id: 2, active: true, word: 'alpha', label: 'enabled' },
          { id: 2, active: false, word: 'alpha', label: 'disabled' },
          { id: 2, active: true, word: 'beta', label: 'other' },
        ])
        b = described_class.from_aoh([{ id: 2, active: true, word: 'alpha', detail: 'match' }])
        result = expect_reference_join(a, b)
        expect(result[:label]).to eq(['enabled'])
        expect_reference_join(a, b, :id, :active_a, :active_b, :word)
      end

      it 'preserves equality between integers and decimals, including signed zero' do
        a = described_class.from_aoh([{ id: 2 }, { id: 0 }, { id: 10**30 }])
        b = described_class.from_aoh([
          { id: BigDecimal('2.0'), detail: 'two' },
          { id: BigDecimal('-0'), detail: 'zero' },
          { id: BigDecimal('1e30'), detail: 'large' },
        ])
        result = expect_reference_join(a, b)
        expect(result[:detail]).to eq(['two', 'zero', 'large'])
      end

      it 'matches dates and datetimes representing the same instant' do
        a = described_class.from_aoh([{ id: Date.new(2026, 1, 1) }])
        b = described_class.from_aoh([
          { id: DateTime.new(2026, 1, 1), detail: 'midnight' },
          { id: DateTime.new(2026, 1, 1, 1, 0, 0, '+01:00'), detail: 'offset' },
          { id: DateTime.new(2026, 1, 1, 1), detail: 'later' },
        ])
        result = expect_reference_join(a, b)
        expect(result[:detail]).to eq(['midnight', 'offset'])
      end

      it 'rechecks decimal NaNs and matches infinities' do
        a = described_class.from_aoh([{ id: BigDecimal('NaN') }, { id: BigDecimal('Infinity') }])
        b = described_class.from_aoh([
          { id: BigDecimal('NaN'), detail: 'nan' },
          { id: BigDecimal('Infinity'), detail: 'infinity' },
        ])
        result = expect_reference_join(a, b)
        expect(result[:detail]).to eq(['infinity'])
      end

      it 'retains evaluator semantics for rational keys' do
        a = described_class.from_aoh([{ id: Rational(1, 3) }])
        b = described_class.from_aoh([{ id: Rational(1, 3), detail: 'third' }])
        result = expect_reference_join(a, b)
        expect(result[:detail]).to eq(['third'])
      end

      it 'retains arbitrary, mixed, and cross join conditions' do
        expect_reference_join(left, right, 'id_a == id_b || id_b == 3')
        expect_reference_join(left, right, :id, 'detail_b != "last match"')
        expect_reference_join(left, right, join_type: :cross)
      end

      it 'preserves joins between differently named columns' do
        other = described_class.from_aoh([{ employee: 2, detail: 'match' }])
        result = expect_reference_join(left, other, :id_a, :employee_b)
        expect(result[:label]).to eq(['second', 'duplicate'])
      end
    end
  end
end
