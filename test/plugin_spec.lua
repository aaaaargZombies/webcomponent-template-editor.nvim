local text = {
  '`',
  '      <h1>${this.sayHello(this.name)}!</h1>',
  '      <button @click=${this._onClick} part="button">',
  '        Click Count: ${this.count}',
  '      </bu\n		tton>',
  '      <slot></slot>',
  '    `',
}

P(text)
