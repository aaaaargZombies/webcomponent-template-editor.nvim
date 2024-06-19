local wc = require('webcomponent-template-editor')
local Array = require('webcomponent-template-editor.utils')
P = function(v)
  print(vim.inspect(v))
  return v
end

local template_literal = {
  '`',
  '      <h1>${this.sayHello(this.name)}!</h1>',
  '      <button @click=${this._onClick} part="button">',
  '        Click Count: ${this.count}',
  '      </bu\n		tton>',
  '      <slot></slot>',
  '    `',
}

local template_contents = {
  '',
  '      <h1>${this.sayHello(this.name)}!</h1>',
  '      <button @click=${this._onClick} part="button">',
  '        Click Count: ${this.count}',
  '      </bu\n		tton>',
  '      <slot></slot>',
  '    ',
}

local template_literal_min = {
  '`<h1>${this.sayHello(this.name)}!</h1>`',
}

local template_contents_min = {
  '<h1>${this.sayHello(this.name)}!</h1>',
}

describe('unit tests for webcomponent-template-editor', function()
  it('removes backquotes from array of strings', function()
    local result = wc.remove_backquotes(template_literal)
    assert.are.same(template_contents, result)
  end)

  it('adds back backquotes from array of strings', function()
    local result = wc.replace_backquotes(template_contents)
    assert.are.same(template_literal, result)
  end)
  it('removes backquotes from array of strings', function()
    local result = wc.remove_backquotes(template_literal_min)
    assert.are.same(template_contents_min, result)
  end)

  it('adds back backquotes from array of strings', function()
    local result = wc.replace_backquotes(template_contents_min)
    assert.are.same(template_literal_min, result)
  end)

  it('uncons on ampty array returns nil and empty array', function()
    local x, xs = Array.uncons({})
    assert.is_nil(x)
    assert.are.same({}, xs)
  end)

  it('uncons on singleton array of Int returns Int and empty array', function()
    local x, xs = Array.uncons({ 1 })
    assert.are.equal(x, 1)
    assert.are.same({}, xs)
  end)

  it('uncons on array of Ints returns Int and array of remaining ints', function()
    local x, xs = Array.uncons({ 1, 2, 3 })
    assert.are.equal(x, 1)
    assert.are.same({ 2, 3 }, xs)
  end)

  it('maps + 1 on to an array of ints', function()
    local ints = { 1, 2, 3, 4, 5 }
    local incremented = { 2, 3, 4, 5, 6 }
    local result = Array.map(function(n)
      return n + 1
    end, ints)

    assert.are.same(incremented, result)
  end)

  it('uses reduce to sum an array of ints', function()
    local ints = { 1, 2, 3, 4, 5 }
    local result = Array.reduce(function(n, acc)
      return n + acc
    end, 0, ints)

    assert.are.equal(15, result)
  end)

  it('sort returns a smol to large array as default', function()
    local sorted = { 1, 2, 3, 4, 5 }
    local borked = { 2, 1, 3, 5, 4 }
    local result = Array.sort(borked)

    assert.are.same(sorted, result)
  end)

  it('can use sort to reverse an array', function()
    local sorted = { 1, 2, 3, 4, 5 }
    local reversed = { 5, 4, 3, 2, 1 }
    local result = Array.sort(sorted, function(a, b)
      return a > b
    end)

    assert.are.same(reversed, result)
  end)
end)
