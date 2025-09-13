import { describe, it, expect } from 'vitest';
import { parseFromDsl } from '../../../domain/dsl/parser';

// 최소 문자열 DSL (줄단위 파서 규칙에 맞춘 key: value 형태)
const DSL = [
  'version: 0.1',
  'source: csv tests/fixtures/minimal.csv',
  'fields: id,name',
  'format: table'
].join('\n');

describe('DSL parser v0.1', () => {
  it('parses minimal spec', () => {
    const spec = parseFromDsl(DSL);
    expect(spec.source?.type).toBe('csv');
    expect(spec.fields.map(f => f.name)).toEqual(['id','name']);
  });
});
