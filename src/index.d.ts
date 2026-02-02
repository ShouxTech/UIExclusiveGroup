declare class UIExclusiveGroup {
	static init(): void;

	constructor();

	public add(uiObject: GuiBase2d): void;
	public remove(uiObject: GuiBase2d): void;
}

export = UIExclusiveGroup;